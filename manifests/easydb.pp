define mysql::easydb (
	$ensure = true
) {
	mysql_database {$name: ensure => $ensure}
	mysql_user {"${name}@localhost":
		password_hash => mysql_password($name);
	}
	mysql_grant {"${name}@localhost/${name}":
		privileges => [ 
			"select_priv", "insert_priv", "update_priv", "delete_priv",
			"create_priv", "drop_priv", "index_priv", "alter_priv", 
			"alter_routine_priv", "create_routine_priv", "execute_priv",
			"lock_tables_priv", "references_priv", "show_view_priv"
		],
		require => Mysql_user["${name}@localhost"];
	}
}
