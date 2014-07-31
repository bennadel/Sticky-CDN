component
	output = false
	hint = "I represent a remote object."
	{

	/**
	* I initialize the remote object.
	* 
	* @headersIn I am the collection of headers extracted from the remote response.
	* @contentIn I am the binary content extracted from the remote response.
	* @output false
	*/
	public any function init(
		required struct headersIn,
		required binary contentIn
		) {

		// Store the properties.
		headers = headersIn;
		content = contentIn;

		// Attempt to build the expiration date out of the headers.
		expiresAt = getExpirationFromHeaders();

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I return binary content of the remote object.
	* 
	* @output false
	*/
	public binary function getContent() {

		return( content );

	}


	/**
	* I return the calculated expiration date.
	* 
	* @hint I raise an exception if the expiration date could not be calculated.
	* @output false
	*/
	public date function getExpiresAt() {

		if ( ! hasExpiration() ) {

			throw( type = "Sticky.InvalidState", message = "Remote object doesn't have expiration." );

		}

		return( expiresAt );

	}


	/**
	* I return the headers for the remote object.
	* 
	* @output false
	*/
	public struct function getHeaders() {

		return( headers );

	}


	/**
	* I determine if the expiration date could be calculated from the internal headres.
	* 
	* @output false
	*/
	public boolean function hasExpiration() {

		return( isDate( expiresAt ) );

	}


	// ---
	// PRIVATE METHODS.
	// ---


	/**
	* I attempt to extract an expiration date from the internal headers.
	* 
	* @output false
	*/
	public any function getExpirationFromHeaders() {

		// Catch any error that occur from people putting non-standard values in the 
		// headers. We don't want that to break the actual workflow.
		try {

			for ( var headerName in headers ) {

				if ( headerName == "Expires" ) {

					return( parseExpiresHeader( headers[ headerName ] ) );

				} else if ( headerName == "Cache-Control" ) {

					return( parseCacheControlHeader( headers[ headerName ] ) );

				}

			}

		// Catch any parsing errors.
		} catch ( any error ) {

			// ...

		}

		// If we made it this far, there were not expiration-based headers; or, they 
		// couldn't be parsed properly. 
		return( "" );

	}


	/**
	* I return an expiration date based on the max-age portion of the Cache-Control header.
	* 
	* @hint I raise an exception if the max-age value doesn't exist.
	* @output false
	*/
	public date function parseCacheControlHeader( required string value ) {

		var utcNow = dateConvert( "local2utc", now() );

		var maxAgePair = reMatch( "(?i)max-age\s*=\s*\d+", value );
		
		var maxAgeInSeconds = listLast( maxAgePair[ 1 ], "= " );

		return( dateAdd( "s", maxAgeInSeconds, utcNow ) );

	}


	/**
	* I return an expiration date baed on the expires header.
	* 
	* @hint I raise an exception if the header can't be parsed as a date.
	* @output false
	*/
	public date function parseExpiresHeader( required string value ) {

		return( parseDateTime( value ) );

	}

}