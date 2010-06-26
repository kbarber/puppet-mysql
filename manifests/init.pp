class mysql {
	mysql::server { params:
		rootpw => $mysql_rootpw,
		enable => true
	}

	$_db_list = split($mysql_db_list, ",")
	mysql::easydb{$_db_list: 
		ensure => present
	}

}
