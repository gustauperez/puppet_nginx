class netcentric_1 (
	$domain		= 'domain.com',
	$fwd_port	= '443',
	$ssl_cert	= '/etc/nginx/ssl/nginx.crt',
	$ssl_key	= '/etc/nginx/ssl/nginx.key',
	$dhparam	= '/etc/nginx/ssl/dhparam.pem') {

	apt::key { 'nginx_labs':
		id      => '573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62',
		server  => 'ha.pool.sks-keyservers.net',
	}

	class{'nginx': 
		manage_repo => true,
		package_source => 'nginx-mainline',
		log_format => {
			forward => '$remote_addr - $remote_user [$time_local] $request_time "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for" $scheme $upstream_addr'
		}
	}

	file { '/etc/nginx/ssl':
		ensure	=> 'directory',
		owner	=> 'www-data',
		mode	=> '0600',
	}
	
	file { $ssl_cert:
		source		=> 'puppet:///modules/netcentric_1/ssl/nginx.crt',
		path 		=> $ssl_cert,
		notify		=> Service['nginx'],
		owner		=> 'www-data',
		mode		=> '0444'
	}
	file { $ssl_key:
		source		=> 'puppet:///modules/netcentric_1/ssl/nginx.key',
		path 		=> $ssl_key, 	
		notify		=> Service['nginx'],
		owner		=> 'www-data',
		mode		=> '0400'
	}
	file { $dhparam:
		source		=> 'puppet:///modules/netcentric_1/ssl/dhparam.pem',
		path 		=> $dhparam,
		notify		=> Service['nginx'],
		owner		=> 'www-data',
		mode		=> '0644'
	}

	nginx::resource::upstream { 'domain':
		ensure  => present,
		members => {
			'10.10.10.10:80' => {
				server 		=> '10.10.10.10',
				port   		=> 80,
				max_fails	=> 3,
				fail_timeout	=> '30s',
			}
		},
	}

	nginx::resource::server{$domain:
		listen_port	=> 443,
		proxy		=> 'http://domain',
		ssl		=> true,
		ssl_cert	=> $ssl_cert,
		ssl_key		=> $ssl_key,
		ssl_dhparam	=> $dhparam,
	}

	nginx::resource::location{'/resource2':
		proxy		=> 'http://20.20.20.20:80/' ,
		server		=> $domain,
		ssl_only        => true,
		ssl		=> true,
	}

	nginx::resource::location{'/health':
		proxy		=> 'http://20.20.20.20:80/health' ,
		server		=> 'domain.com',
		ssl_only        => true,
		ssl		=> true,
	}

	nginx::resource::server{'localhost':
		listen_port => 8080,
		resolver    => ['8.8.8.8'],
		proxy       => 'http://$http_host$uri$is_args$args',
		format_log  => forward,
	}

}
