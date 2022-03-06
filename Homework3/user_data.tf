locals {
  	user_data_nginx = trimspace(<<EOF
		#! /bin/bash
        apt update
		apt install -y awscli
		apt install -y nginx
		systemctl start nginx
		systemctl enable nginx
		sudo sh -c 'echo "#!/bin/bash \nsudo aws s3 cp /var/log/nginx/access.log  s3://eliezer-bucket/logs/access_" > example.sh'
 		sed 's/_/_$(date +\%Y\%m\%d\%H\%M\%S)/' example.sh > s3.sh ; sudo mv s3.sh /etc/cron.hourly/
		sudo chmod +x /etc/cron.hourly/s3.sh
		rm -rf example.sh
		echo "<h1>'Welcome to Grandpa's Whiskey' $HOSTNAME</h1>" | sudo tee /var/www/html/index.nginx-debian.html
	EOF
	)
    user_data_db = trimspace(<<EOF
		#! /bin/bash
        apt-get update
		apt-get install -y nginx
		systemctl start nginx
		systemctl enable nginx
		echo "<h1>'DBS APP'</h1>" | sudo tee /var/www/html/index.nginx-debian.html
	EOF
	)
}