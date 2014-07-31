<cfscript>
	
	// Set up the default response structure.
	response = {
		statusCode = 404,
		statusText = "Not Found",
		filepath = "",
		headers = {}
	};

	// Try to pull the request objected from the local cache (if it's not local, it will
	// be pulled from the remote origin server).
	try {

		// We'll be making requests to the origin using the same protocol.
		protocol = ( https == "on" ? "https" : "http" );

		localObject = application.cdn.get( protocol, cgi.server_name, cgi.path_info );

		// If we made it this far (without throwing exception), then we were ablet to 
		// obtain the remote resource. 
		response.statusCode = 200;
		response.statusText = "OK";
		response.filepath = localObject.filepath;
		response.headers = localObject.metadata.headers;

	// Catch any errors during the pull from the origin server.
	} catch ( Sticky.Notfound error ) {

		// If the object couldn't be found on the remote origin server, then simply let 
		// the default 404 response fall-through.

	// Catch any unexpected errors.
	} catch ( any error ) {

		// TODO: Log this error, wasn't expected.

	}

</cfscript>

<!--- Set the appropriate status. --->
<cfheader
	statuscode="#response.statusCode#"
	statustext="#response.statusText#"
	/>

<!--- Pass-through any headers that were taken from the origin. --->
<cfloop 
	item="headerName" 
	collection="#response.headers#">
	
	<cfheader
		name="#headerName#"
		value="#response.headers[ headerName ]#"
		/>

</cfloop>

<!--- If we found the file, stream it to the client. --->
<cfif len( response.filepath )>
	
	<cfcontent file="#response.filepath#" />

</cfif>