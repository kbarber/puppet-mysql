define mysql::server (
	$conf_path = undef,
	$datadir = undef,
	$default_character_set = utf8,
	$default_storage_engine = innodb,
	$enable = false,
	$innodb_file_per_table = true,
	$log_error = undef,
	$log_slow_queries = true,
	$mysqladmin_path = undef,
	$package = undef,
	$pid_file = undef,
	$rootpw,
	$skip_bdb = undef,
	$socket = undef,
	$user = undef
	) {

	$resource_name = "mysql::server"

	if($name != "params") {
		fail("${resource_name}: This function is a singleton. Make sure the resource name is 'params'.")
	}


	case $operatingsystem {
		Fedora: {
			case $operatingsystemrelease {
				/^(12|13)$/: {
					if(!$conf_path) { $_conf_path = "/etc/my.cnf" }
					if(!$datadir) { $_datadir = "/var/lib/mysql/data/" }
					if(!$log_error) { $_log_error = "/var/log/mysqld.log" }
					if(!$mysqladmin_path) { $_mysqladmin_path = "/usr/bin/mysqladmin" }
					if(!$package) { $_package = "mysql-server" }
					if(!$pid_file) { $_pid_file = "/var/run/mysqld/mysqld.pid" }
					if(!$service) { $_service = "mysqld" }
					if(!$socket) { $_socket = "/var/lib/mysql/mysql.sock" }
					if(!$user) { $_user = "mysql" }
					if(!$skip_bdb) { $_skip_bdb = false }
				}
			}
		}
	}

	# Presume the OS did not match and because these args are necessary, just 
	# bail with an error.
	if(!($_datadir and $_log_error and $_pid_file and $_socket and 
			 $_user and $_mysqladmin_path)) { 
		fail("${resource_name}: Unsupported operating system: ${operatingsystem} version ${operatingsystemrelease} and you have not setup the args for: datadir, log_error, mysqladmin_path, pid_file, socket, user.")
	}

	# Fix other vars
	$_default_storage_engine = $default_storage_engine
	$_default_character_set = $default_character_set
	$_innodb_file_per_table = $innodb_file_per_table
	$_log_slow_queries = $log_slow_queries
	$_rootpw = $rootpw

	package {
		$_package:
			ensure => installed;
	}
	file {
		"/etc/my.d":
			ensure => directory;
		$_datadir:
			ensure => directory,
			owner => "mysql",
			group => "mysql",
			mode => "0755";
		$_conf_path:
			content => template("mysql/my.cnf"),
			require => Package[$_package];
		"/root/.my.cnf":
			content => template("mysql/my.cnf.client"),
			require => Package[$_package],
			owner => root,
			group => root,
			mode => "0400";
		"/usr/local/bin/setmysqlpass.sh":
			content => template("mysql/setmysqlpass.sh"),
			require => Package[$_package],
			owner => root,
			group => root,
			mode => "0500";
	}
	if($enable) {
		exec {
			'set_mysql_rootpw':
				command => "/usr/local/bin/setmysqlpass.sh ${_rootpw}",
				unless => "${_mysqladmin_path} -uroot -p${_rootpw} status > /dev/null",
				require => [ File['/usr/local/bin/setmysqlpass.sh'], Package[$_package] ],
		}
	}
	service {
		$_service:
			ensure => $enable ? {
				true => running,
				false => stopped
			},
			enable => $enable,
			hasstatus => true,
			require => [ Package[$_package], File[$_conf_path] ];
	}
}
