component
	output = false
	hint = "I define the application settings and event handlers."
	{

	// Define the application settings.
	this.name = hash( getCurrentTemplatePath() );
	this.applicationTimeout = createTimeSpan( 1, 0, 0, 0 );
	this.sessionManagement = false;

	// Define the application mappings.
	this.mappings[ "/" ] = getDirectoryFromPath( getCurrentTemplatePath() );
	this.mappings[ "/cache" ] = ( this.mappings[ "/" ] & "cache/" );
	this.mappings[ "/logs" ] = ( this.mappings[ "/" ] & "logs/" );
	this.mappings[ "/models" ] = ( this.mappings[ "/" ] & "models/" );
	this.mappings[ "/wwwroot" ] = ( this.mappings[ "/" ] & "wwwroot/" );


	// ---
	// PUBLIC METHODS.
	// ---


	/**
	* I initialize the application. If I return False, the application will not load.
	* 
	* @output false
	*/
	public boolean function onApplicationStart() {

		// The config holds the mappings of CDN urls to Origin urls, as well as other optional
		// CDN values (like default expiration times for remote objects).
		var config = new models.Config( deserializeJson( fileRead( expandPath( "/config.json" ) ) ) );

		application.cdn = new models.StickyCDN( config, expandPath( "/cache/" ) );

		return( true );

	}


	/**
	* I initialize the request. If I return False, the request will not load.
	* 
	* @output false
	*/
	public boolean function onRequestStart( required string scriptName ) {

		// Check for application re-initialization.
		if ( ! isNull( url.init ) ) {

			onApplicationEnd( application );
			onApplicationStart();

		}

		return( true );

	}


	/**
	* I execute the request. I override the natural mapping of the request to the file.
	* 
	* @output false
	*/
	public void function onRequest( required string scriptName ) {

		// Render the response - all requests go through the main use-case.
		include "/wwwroot/index.cfm";

	}


	/**
	* I teardown the application.
	* 
	* @output false
	*/
	public void function onApplicationEnd( required any applicationScope ) {

		// Once the application has ended, the application mappings no longer work; 
		// however, we can still access the mappings defined in this component instance.
		var logPath = ( this.mappings[ "/logs" ] & "sticky.log" );
		
		// Any error that occurs in the onApplicationEnd() event handler doesn't get 
		// handled well by the ColdFusion application server. As such, we need to take 
		// special care to log things more manually.
		try {

			applicationScope.cdn.cleanup();

		// Catch any event-handler errors.
		} catch ( any error ) {

			writeDump( var = error, output = logPath, format = "text" );

		}

	}

}