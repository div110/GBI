read -p "heslo pro MariaDB: " $password
emerge dev-db/mariadb

mysql_secure_installation <<-YO
$password
n
n
y
y
y
y
YO
