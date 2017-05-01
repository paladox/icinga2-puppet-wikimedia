# = Class: icinga2::plugins
#
# Sets up icinga2 check_plugins and notification commands
class icinga2::plugins {
    package { 'nagios-nrpe-plugin':
        ensure => present,
    }
    file { '/usr/lib/nagios':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/eventhandlers':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/eventhandlers/submit_check_result':
        source => 'puppet:///modules/icinga2/submit_check_result.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/var/run/icinga2/cmd':
        ensure => directory,
        owner  => 'nagios',
        group  => 'www-data',
        mode   => '0775',
    }
    file { '/etc/nagios-plugins':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    # TODO: Purge this directoy instead of populating it is probably not very
    # future safe. We should be populating it instead
    file { '/etc/nagios-plugins/config':
        ensure  => directory,
        purge   => true,
        recurse => true,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    File <| tag == nagiosplugin |>

    file { '/usr/lib/nagios/plugins/check_mysql-replication.pl':
        source => 'puppet:///modules/icinga2/check_mysql-replication.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_longqueries':
        source => 'puppet:///modules/icinga2/check_longqueries.pl',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_MySQL.php':
        source => 'puppet:///modules/icinga2/check_MySQL.php',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/usr/lib/nagios/plugins/check_ram.sh':
        source => 'puppet:///modules/icinga2/check_ram.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    class { '::nagios_common::commands':
    }

    include ::passwords::nagios::mysql

    $nagios_mysql_check_pass = $passwords::nagios::mysql::mysql_check_pass

    nagios_common::check_command::config { 'mysql.cfg':
        ensure     => present,
        content    => template('icinga2/check_commands/mysql.cfg.erb'),
        config_dir => '/etc/icinga2',
        owner      => 'root',
        group      => 'root',
    }
}
