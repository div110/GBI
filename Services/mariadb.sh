echo "dev-db/mariadb USE=\"+server\"" > /etc/portage/package.use/mariadb
read -p "heslo pro MariaDB: " $password
emerge dev-db/mariadb
/etc/init.d/mariadb start
sudo rc-update add mariadb default
mysql_secure_installation <<-YO
$password
n
n
y
y
y
y
YO
