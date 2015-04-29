#!/bin/bash
#create nginx server blocks (aka virtualhost) config

declare -a  dirname=( domain_com domain_net )

declare -a domain=( domain.com domain.net)



echo "

index index.php index.html index.htm;

location ~ \.php$ {
  # Zero-day exploit defense.
  # http://forum.nginx.org/read.php?2,88845,page=3
  # Won't work properly (404 error) if the file is not stored on this server, which is entirely possible with php-fpm/php-fcgi.
  # Comment the 'try_files' line out if you set up php-fpm/php-fcgi on another machine.  And then cross your fingers that you won't get hacked.
  try_files \$uri =404;

  fastcgi_split_path_info ^(.+\.php)(/.+)$;
  include /etc/nginx/fastcgi_params;

  # As explained in http://kbeezie.com/view/php-self-path-nginx/ some fastcgi_param are missing from fastcgi_params.
  # Keep these parameters for compatibility with old PHP scripts using them.
  fastcgi_param PATH_INFO       \$fastcgi_path_info;
  #fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_path_info;
  fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;

  # Some default config
  fastcgi_connect_timeout        60;
  fastcgi_send_timeout          180;
  fastcgi_read_timeout          180;
  fastcgi_buffer_size          128k;
  fastcgi_buffers            4 256k;
  fastcgi_busy_buffers_size    256k;
  fastcgi_temp_file_write_size 256k;

  fastcgi_intercept_errors    on;
  fastcgi_ignore_client_abort off;
  fastcgi_index index.php;
  fastcgi_pass unix:/var/run/php5-fpm.sock;
}" > /etc/nginx/php.conf

#-------------------

for i in {0..18}; #in ${dirname[@]}
do
echo ${dirname[$i]}
echo ${domain[$i]}






echo " 
server {
  server_name www.${domain[$i]} ${domain[$i]};
  include /etc/nginx/php.conf;
  default_type text/html;
  #index index.php index.html
  root /var/www/domains/${dirname[$i]}/;

	location ~* \.(?:ico|css|js|gif|jpe?g|png)$ {
		# Some basic cache-control for static files to be sent to the browser
		root /var/www/domains/${dirname[$i]}/;
		expires max;
		add_header Pragma public;
		add_header Cache-Control \"public, must-revalidate, proxy-revalidate\";
	}

}
" > /etc/nginx/sites-available/www.${domain[$i]}

#/etc/nginx/sites-available/default 





#enable website
ln -s /etc/nginx/sites-available/www.${domain[$i]}  /etc/nginx/sites-enabled/www.${domain[$i]}

done



#ln -s /etc/nginx/sites-available/default  /etc/nginx/sites-enabled/default
nginx -t && nginx -s reload
service php5-fpm restart

#--------------------

#benchmark webserver
#ab -c 1000 -n 100000 http://www.myfreepornpics.com/www.pornhub.com/index.html


#---------------------

##hardening
#/sbin/sysctl -w kernel.modules_disabled=1
#/sbin/sysctl -w kernel.panic_on_oops=1
#echo "
# # Disables the magic SysRq key
#     kernel.sysrq = 0
#" >> /etc/sysctl.conf

#http://www.debian.org/doc/manuals/securing-debian-howto/
