component
	output = false
	hint = "I act as a proxy to the remote origin servers."
	{

	/**
	* I initialize the remote proxy.
	* 
	* @output false
	*/
	public any function init() {

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I pull down the remote object from the origin server and normalize the response
	* using the given target headers.
	* 
	* @resource I am the remote URL for the origin object.
	* @headers I am the list of header names to pull out of the response.
	* @hint I raise an exception if the remote object cannot be found.
	* @output false
	*/
	public any function get( 
		required string resource,
		required array headers
		) {

		var originRequest = new Http(
			method = "get",
			url = resource,
			getAsBinary = "yes"
		);

		var result = originRequest.send().getPrefix();

		// If the remote object wasn't found, raise exception.
		if ( ! reFind( "2\d\d", result.statusCode ) ) {

			throw( type = "Sticky.NotFound", message = "Remote object not found on origin server." );

		}

		// If the remote object was found, but is empty, raise exception.
		if ( ! arrayLen( result.fileContent ) ) {

			throw( type = "Sticky.NotFound", message = "Remote object is empty." );

		}

		return(
			new RemoteObject( 
				pluckHeaders( result.responseHeader, headers ),
				result.fileContent
			)
		);

	}


	// ---
	// PRIVATE METHODS.
	// ---


	/**
	* I pull the target headers out of the response headers.
	* 
	* @responseHeaders I am the headers found in the HTTP response.
	* @targetHeaders I am the list of header names to pull out of the response.
	* @output false
	*/
	private struct function pluckHeaders(
		required struct responseHeaders,
		required array targetHeaders
		) {

		var headers = {};

		for ( var headerName in targetHeaders ) {

			if ( structKeyExists( responseHeaders, headerName ) ) {

				var value = responseHeaders[ headerName ];

				// If the header is not a simple value, then ColdFusion has returned it as an
				// array-like Struct. We need to collapse the struct down into a simple value
				// that can be easily returned by the CDN.
				if ( ! isSimpleValue( value ) ) {

					var compoundHeaderValue = [];

					// Loop over the index-like keys.
					for ( var pseudoIndex in value ) {

						arrayAppend( compoundHeaderValue, value[ pseudoIndex ] );

					}

					value = arrayToList( compoundHeaderValue, ", " );

				}

				headers[ headerName ] = value;

			}
			
		}

		return( headers );

	}

}