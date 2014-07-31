component
	output = false
	hint = "I provide high-level access to the Sticky CDN development environment."
	{

	/**
	* I initialize the Sticky CDN.
	* 
	* @output false
	*/
	public any function init(
		required any configIn,
		required string cacheDirectoryIn
		) {

		// Store properties.
		config = configIn;
		cachedDirectory = cacheDirectoryIn;

		// I provide easier access to the remote objects.
		remoteProxy = new RemoteProxy();

		// I provide easier access to the local file IO.
		objectStore = new ObjectStore( cacheDirectoryIn );

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I clean up the state of the CDN, which may have objects that have expired but have
	* not yet been flushed from the local object store.
	* 
	* @output false
	*/
	public void function cleanup() {

		objectStore.removeExpiredObjects();

	}


	/**
	* I get the cached object. If the object is not cached locally, it is pulled from the
	* origin server and cached locally.
	* 
	* @hint I raise an exception if the object cannot be found (locally or remotely).
	* @output false
	*/
	public struct function get(
		required string protocol,
		required string domain,
		required string key
		) {

		// Make sure that we have a mapping to the origin server.
		if ( ! config.hasOrigin( domain ) ) {

			throw( type = "Sticky.NotFound", message = "No origin server matches request." );

		}

		// Make sure there is a key for the origin file.
		if ( ! len( key ) ) {

			throw( type = "Sticky.NotFound", message = "No key was provided." );

		}

		// Get the pass-through URL for the requested object on the origin server.
		var origin = config.getOrigin( domain );
		var resource = "#protocol#://#origin##key#";

		// Because we need to populate the cache from the origin server, we want to single-
		// thread the processing on a per-token basis. This way, two requests aren't trying
		// to read the same file from the remote at the same time.
		lock 
			name = resource
			type = "exclusive"
			timeout = config.getLockTimeout()
			{

			try {

				var localObject = objectStore.get( resource );

				// For debugging purposes, indicate that the object was pulled from the 
				// local cache, and not from the remote origin server.
				localObject.metadata.headers[ "X-Sticky-CDN-Cache-Hit" ] = "true";

			} catch ( any error ) {

				// NOTE: Pulling from the remote will raise exception if not found.
				var remoteObject = remoteProxy.get( resource, config.getHeaders() );

				objectStore.put(
					resource,
					remoteObject,
					( remoteObject.hasExpiration() ? remoteObject.getExpiresAt() : config.getDefaultExpiration() )
				);

				var localObject = objectStore.get( resource );

			}

		} // END: Lock.

		return( localObject );

	}

}