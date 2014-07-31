component
	output = false
	hint = "I define the configuration and default values for the Sticky CDN."
	{

	/**
	* I initialize the configuration object using the given hash as the set of explicitly-
	* provided options.
	* 
	* @output false
	*/
	public any function init( required struct settings ) {

		if ( isNull( settings.origin ) ) {

			throw( type = "Sticky.Config.MissingOrigin", message = "No origin map was provided." );

		}

		if ( structIsEmpty( settings.origin ) ) {

			throw( type = "Sticky.Config.EmptyOrigin", message = "No origin mappings were provided." );

		}

		origin = settings.origin;

		// Set up the core headers that we will always check for, regardless of what 
		// additional headers have been defined.
		headers = [
			"Cache-Control",
			"Content-Disposition",
			"Content-Length",
			"Content-Type",
			"ETag",
			"Expires"
		];

		// Append any additional headers that the user has provided.
		if ( ! isNull( settings.headers ) ) {

			for ( var headerName in settings.headers ) {

				if ( ! arrayContains( headers, headerName ) ) {

					arrayAppend( headers, headerName );
					
				}

			}
			
		}

		// Set the lock timeout - this is the amount of time that the single-thread lock
		// will be held while attempting to pull an object from the cache (and then 
		// possibly the remote origin server).
		if ( isNull( settings.lockTimeout ) ) {

			lockTimeout = 10;

		} else {

			lockTimeout = settings.lockTimeout;

		}

		// Set the default expiration. If the remote object has some form of expiration 
		// header, we'll use that. However, if the remote object doesn't contain an 
		// expiration headers, then this is how long the object will be cached in the CDN.
		if ( isNull( settings.expirationInDays ) ) {

			expirationInDays = 7;

		} else {

			expirationInDays = settings.expirationInDays;

		}

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I determine if the configuration contains a mapping for the local domain.
	* 
	* @output false
	*/
	public boolean function hasOrigin( required string domain ) {

		return( structKeyExists( origin, domain ) );

	}


	/**
	* I get the default expiration for this point in time. This the expiration date that
	* we'll use for expiration if the remote object doesn't have an expiration.
	* 
	* @hint Date is returned in UTC timezone.
	* @output false
	*/
	public date function getDefaultExpiration() {

		var localExpiration = dateAdd( "d", expirationInDays, now() );

		return( dateConvert( "local2utc", localExpiration ) );

	}


	/**
	* I return the collection of headers that we want to try to pull out of the remote
	* object when we pull it from the origin.
	* 
	* @output false
	*/
	public array function getHeaders() {

		return( headers );

	}


	/**
	* I return the lock timeout for the single-threading of the remote origin pull.
	* 
	* @output false
	*/
	public numeric function getLockTimeout() {

		return( lockTimeout );

	}


	/**
	* I get the remote origin server that maps from the given domain.
	* 
	* @hint Raises exception if origin is not found in config.
	* @output false
	*/
	public string function getOrigin( required string domain ) {

		if ( ! hasOrigin( domain ) ) {

			throw( type = "Sticky.Config.OriginNotFound", message = "There is no origin that maps from the given domain." );

		}

		return( origin[ domain ] );

	}

}