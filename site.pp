node 'your_node' {
        class { 'nginx':
        }
        # Files location, replace /home/www your location
        $www_location = '/home/www'
        # PHPBB3 forum
        # Replace phpbb3.local your domain name
        $phpbb = 'phpbb3.local'
        # Create directory phpbb3
        file { "${www_location}/phpbb3":
                ensure  =>      'directory',
                owner   =>      'root',
                group   =>      'root',
                mode    =>      '0755',
        }
        nginx::resource::server { "${phpbb}":
                listen_port     =>      80,
                www_root        =>      "${www_location}/phpbb3",
                access_log      =>      "/var/log/nginx/phpbb3_${name}_access.log",
                error_log       =>      "/var/log/nginx/phpbb3_${name}_error.log",
                error_pages     => {
                        '404'           =>      '/50x.html',
                        '500'           =>      '/50x.html',
                        '502'           =>      '/50x.html',
                        '503'           =>      '/50x.html',
                        '504'           =>      '/50x.html',
                },
                try_files       =>      [ '$uri', '$uri/', '@rewriteapp' ],
        }
        nginx::resource::location { 'phpbb3_@rewriteapp':
                server          =>      "${phpbb}",
                location        =>      '@rewriteapp',
                www_root        =>      "${www_location}/phpbb3",
                rewrite_rules   =>      [ '^(.*)$ /app.php/$1 last' ],
                index_files     =>      [],
        }
        # Deny access to internal phpbb files.
        nginx::resource::location { 'phpbb3_config':
                server          =>      "${phpbb}",
                location        =>      '~ /(config\.php|common\.php|includes|cache|files|store|images/avatars/upload)',
                index_files     =>      [],
                location_deny   =>      [ 'all' ],
                # deny was ignored before 0.8.40 for connections over IPv6.
                # Use internal directive to prohibit access on older versions.
                internal        =>      true,
        }
        # Error sites location. It is based on Debian 8 Jessie default location. 
        nginx::resource::location { 'phpbb3_50x.html':
                server          =>      "${phpbb}",
                www_root        =>      '/usr/share/nginx/html',
                location        =>      '= /50x.html',
                index_files     =>      [ 'index.html' ],
        }
        nginx::resource::location { "phpbb3_php":
                server                  =>      "${phpbb}",
                www_root                =>      "${www_location}/phpbb3",
                location                =>      '~ \.php(/|$)',
                fastcgi_index           =>      'index.php',
                fastcgi                 =>      'unix:/var/run/php5-fpm.sock',
                fastcgi_split_path      =>      '^(.+\.php)(/.*)$',
                fastcgi_param           => {
                        'PATH_INFO'             =>      '$fastcgi_path_info',
                        'SCRIPT_FILENAME'       =>      '$realpath_root$fastcgi_script_name',
                        'DOCUMENT_ROOT'         =>      '$realpath_root',
                },
                try_files               =>      [ '$uri', '$uri/', '/app.php$is_args$args' ],
        }
        nginx::resource::location { 'phpbb3_install':
                server                  =>      "${phpbb}",
                www_root                =>      "${www_location}/phpbb3",
                location                =>      '/install/',
                index_files             =>      [],
                try_files               =>      [ '$uri', '$uri/', '@rewrite_installapp' ],
                raw_append              =>      [
                        'location ~ \.php(/|$) {',
                        'fastcgi_pass unix:/var/run/php5-fpm.sock;',
                        'include /etc/nginx/fastcgi_params;',
                        'fastcgi_split_path_info ^(.+\.php)(/.*)$;',
                        'fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;',
                        'fastcgi_param DOCUMENT_ROOT $realpath_root;',
                        'try_files $uri $uri/ /install/app.php$is_args$args;',
                        '}'
                ],
        }
        nginx::resource::location { 'phpbb3_@rewrite_installapp':
                server          =>      "${phpbb}",
                location        =>      '@rewrite_installapp',
                www_root        =>      "${www_location}/phpbb3",
                rewrite_rules   =>      [ '^(.*)$ /install/app.php/$1 last' ],
                index_files     =>      [],
        }
        # Deny access to version control system directories.
        nginx::resource::location { 'phpbb3_svn_git':
                server          =>      "${phpbb}",
                location        =>      '~ /\.svn|/\.git',
                index_files     =>      [],
                location_deny   =>      [ 'all' ],
                # deny was ignored before 0.8.40 for connections over IPv6.
                # Use internal directive to prohibit access on older versions.
                internal        =>      true,
        }
}
