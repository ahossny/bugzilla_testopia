# Install Ubuntu 14.04.6 LTS



#PLEASE MODIFY CREDENTIALS IF NEEDED
#Do not add spaces arround [=] between Key and value
#Do not use those characters in password [  & , $  ]
MySqlRootPass='6!$4C=hW$NMxPVvd'
MySqlBugPass='VM8dn+XuLkfp7U!'



# Super user privilege
sudo su

apt-get update
apt-get install git nano

#download MySQL Server 5.6
debconf-set-selections <<< "mysql-server-5.6 mysql-server/root_password password $MySqlRootPass"
debconf-set-selections <<< "mysql-server-5.6 mysql-server/root_password_again password $MySqlRootPass"
apt-get -y install mysql-server-5.6

#download all dependencies
apt-get install apache2 libappconfig-perl libdate-calc-perl libtemplate-perl libmime-perl build-essential libdatetime-timezone-perl libdatetime-perl libemail-sender-perl libemail-mime-perl libemail-mime-modifier-perl libdbi-perl libdbd-mysql-perl libcgi-pm-perl libmath-random-isaac-perl libmath-random-isaac-xs-perl apache2-mpm-prefork libapache2-mod-perl2 libapache2-mod-perl2-dev libchart-perl libxml-perl libxml-twig-perl perlmagick libgd-graph-perl libtemplate-plugin-gd-perl libsoap-lite-perl libhtml-scrubber-perl libjson-rpc-perl libdaemon-generic-perl libtheschwartz-perl libtest-taint-perl libauthen-radius-perl libfile-slurp-perl libencode-detect-perl libmodule-build-perl libnet-ldap-perl libauthen-sasl-perl libtemplate-perl-doc libfile-mimeinfo-perl libhtml-formattext-withlinks-perl libfile-which-perl libgd-dev libmysqlclient-dev lynx-cur graphviz python-sphinx rst2pdf

cd /var/www/html

# download bugzilla 4.4
git clone --branch release-4.4-stable https://github.com/bugzilla/bugzilla bugzilla

# /etc/mysql/my.cnf
# Set the following values, which increase the maximum attachment size and make it possible to search for short words and terms:
# Alter on Line 52: max_allowed_packet=100M
Add as new line 32, in the [mysqld] section: ft_min_word_len=2
sed -e 's/\[mysqld\]/[mysqld]\nft_min_word_len\t= 2/g' -i /etc/mysql/my.cnf
sed -e "s/max_allowed_packet\s*[=]\s*[0-9]*[a-zA-Z]/max_allowed_packet\t= 100M/g" -i /etc/mysql/my.cnf

# Adds user bugs for Bugzilla and grant privilege to bugs database
mysql -u root "-p$MySqlRootPass" -e "GRANT ALL PRIVILEGES ON bugs.* TO bugs@localhost IDENTIFIED BY '$MySqlBugPass'" 


#Restart MySql
service mysql restart

#Configure Apache2 to bind Bugzilla
sed -e "s/DocumentRoot\s*.*/DocumentRoot \/var\/www\/html\/bugzilla/g" -i /etc/apache2/sites-available/000-default.conf
cat > /etc/apache2/sites-available/bugzilla.conf << EOF
ServerName localhost

<Directory /var/www/html/bugzilla>
  AddHandler cgi-script .cgi
  Options +ExecCGI
  DirectoryIndex index.cgi index.html
  AllowOverride All
</Directory>
EOF

#Configure Apache2
a2ensite bugzilla
a2enmod cgi headers expires

#Restart Apache2
service apache2 restart

#Bugzilla installation directory
cd /var/www/html/bugzilla


#Perl modules, required modules for Bugzilla + Testopia
/usr/bin/perl install-module.pl Email::Send
/usr/bin/perl install-module.pl Text::Diff


#Modify Bugzilla configuration file
#Sets Db password and permission group
sed -e "s/\$webservergroup\s*[=]\s*['][^']*['];/\$webservergroup='www-data';/g" -i /var/www/html/bugzilla/localconfig
sed -e "s/\$db_pass\s*[=]\s*['][^']*['];/\$db_pass='$MySqlBugPass';/g" -i /var/www/html/bugzilla/localconfig


cd /var/www/html/bugzilla

#Download Testopia supports Bugzilla 4.4
wget https://ftp.mozilla.org/pub/mozilla.org/webtools/testopia/testopia-2.5-BUGZILLA-4.2.tar.gz

#Installs Testopia Extension
tar xzvf testopia-2.5-BUGZILLA-4.2.tar.gz


#Check Setup and creates localconfig file
#Configures Bugzilla and Testopia
./checksetup.pl



