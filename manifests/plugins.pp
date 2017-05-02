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
}
