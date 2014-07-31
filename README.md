
# Sticky CDN - Content Delivery Network For Local Development

by [Ben Nadel][bennadel] (on [Google+][googleplus])

This is small ColdFusion application that acts as a Content Delivery Network (CDN) for a local
development environment. It's a simple pass-through cache layer that maps incoming requests to
origin-server requests. It caches the given object and starts serving it up on subsequent 
requests without going back to the origin server.

## Configuring Content Delivery Network

In order to get this local CDN application to work, you have to set up the virtual host in Apache
and then set up the mappings for the request translation.

### Apache Virtual Host

The Apache Virtual Host sets up the sever names as well as the URL rewrite rules. Every request
that comes into Sticky CDN gets rewritten to run through the main index.cfm file.

```conf
<VirtualHost *:80>

	ServerName local.cdn.stickycdn.com
	ServerAlias local.cdn2.stickycdn.com
	ServerAlias local.cdn3.stickycdn.com

	ErrorLog /Path/To/Your/Sites/sticky_cdn/site/logs/error.log
	RewriteLog /Path/To/Your/Sites/sticky_cdn/site/logs/rewrite.log
	# RewriteLogLevel 7

	DocumentRoot "/Path/To/Your/Sites/sticky_cdn/site/wwwroot"
	
	<Directory "/Path/To/Your/Sites/sticky_cdn/site/wwwroot">

		Options Indexes FollowSymLinks
		AllowOverride All
		Order allow,deny
		Allow from all

		# ------------------------------------------------------------ #
		# ------------------------------------------------------------ #

		# Enable URL rewriting.

		RewriteEngine On

		# ------------------------------------------------------------ #
		# ------------------------------------------------------------ #

		# Rewrite all requests to the main index.cfm page (except for the index page).

		RewriteCond  %{REQUEST_URI}  !^/?index.cfm  [NC]
		RewriteRule  /?(.+)  index.cfm/$1  [L,QSA]

	</Directory>

</VirtualHost>
```

Obviously, you need to use paths that make sense for your computer.

### Configuration

Once you have your virtual host set up, you can set up your `config.json` file that lives in 
`site` folder of the repository. At the very least, this configuration file has to have a 
collection of origin server mappings:

```json
{
	"origin": {
		"local.cdn.stickycdn.com": "local.stickycdn.com"
	}
}
```

That's about it. 


[bennadel]: http://www.bennadel.com
[googleplus]: https://plus.google.com/108976367067760160494?rel=author
