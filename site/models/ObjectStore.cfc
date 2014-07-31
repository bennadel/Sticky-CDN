component
	output = false
	hint = "I provide access to the local object store."
	{

	/**
	* I initialize the component.
	* 
	* @cacheDirectoryIn I am the root location of the storage directory.
	* @output false
	*/
	public any function init( required string cacheDirectoryIn ) {

		cacheDirectory = cacheDirectoryIn;

		return( this );

	}


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I get the locally cached version of the remote resource.
	* 
	* @resource I am the remote URL for the given object.
	* @hint I throw an exception if the object does not exist locally.
	* @output false
	*/
	public struct function get( required string resource ) {

		var token = tokenizeResource( resource );

		// The binary path holds the actual object that we want to cache; the meta data 
		// path holds the data about the file and the cache properties.
		var binaryPath = "#cacheDirectory##token#.binary";
		var metadataPath = "#cacheDirectory##token#.json";

		// If one of the files doesn't exist, local data is incomplete.
		if ( ! fileExists( binaryPath ) || ! fileExists( metadataPath ) ) {

			throw( type = "Sticky.NotFound", message = "The requested object is not cached locally." );

		}

		var metadata = deserializeJson( fileRead( metadataPath ) );

		// If the local object is expired, delete it.
		if ( isExpired( metadata.expiresAt ) ) {

			fileDelete( binaryPath );
			fileDelete( metadataPath );

			throw( type = "Sticky.NotFound", message = "The locally-cached object has expired." );

		}

		var localObject = {
			filepath = binaryPath,
			metadata = metadata
		};

		return( localObject );

	}


	/**
	* I cache the remote object for the given time period.
	* 
	* @resource I am the remote URL for the given object.
	* @remoteObject I am the normalized version of the remote object.
	* @expiresAt I am the UTC time after which the object shoudl be flushed from the cache.
	* @output false
	*/
	public void function put(
		required string resource,
		required any remoteObject,
		required date expiresAt
		) {

		var token = tokenizeResource( resource );

		// The binary path holds the actual object that we want to cache; the meta data path 
		// holds the data about the file and the cache properties.
		var binaryPath = "#cacheDirectory##token#.binary";
		var metadataPath = "#cacheDirectory##token#.json";

		var metadata = {
			"cachedAt" = dateConvert( "local2utc", now() ),
			"resource" = resource,
			"expiresAt" = expiresAt,
			"headers" = remoteObject.getHeaders()
		};

		fileWrite( binaryPath, remoteObject.getContent() );
		fileWrite( metadataPath, serializeJson( metadata ) );

	}


	/**
	* I flush all expired objects from the local cache.
	* 
	* @output false
	*/
	public void function removeExpiredObjects() {

		var metadataFiles = directoryList( cacheDirectory, false, "name", "*.json" );

		for ( var metadataFile in metadataFiles ) {

			var metadata = deserializeJson( fileRead( cacheDirectory & metadataFile ) );

			if ( isExpired( metadata.expiresAt ) ) {

				var binaryFile = replace( metadata, ".json", ".binary", "one" );

				fileDelete( cacheDirectory & metadataFile );
				fileDelete( cacheDirectory & binaryFile );

			}

		}

	}


	// ---
	// PRIVATE METHODS.
	// ---


	/**
	* I determine if the given date is expired.
	* 
	* @expiresAt I am expected to be in UTC time.
	* @output false
	*/
	private boolean function isExpired( required date expiresAt ) {

		var cutoff = dateConvert( "local2utc", now() );

		return( expiresAt < cutoff );

	}


	/**
	* I turn the remote resource URL into a unique token for local storage.
	* 
	* @resource I am the remote URL for the given object.
	* @output false
	*/
	private string function tokenizeResource( required string resource ) {

		var prefix = reReplace( getFileFromPath( resource ), "[^a-zA-Z0-9]+", "", "all" );

		if ( len( prefix ) ) {

			prefix &= "-";

		}

		return( lcase( prefix & hash( resource ) ) );

	}

}