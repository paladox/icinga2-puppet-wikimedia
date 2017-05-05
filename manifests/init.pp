# Class: icinga2
#
# Sets up an icinga server, with appropriate config & plugins
# FIXME: A lot of code in here (init script, user setup, logrotate,
# and others) should probably come from the icinga deb package,
# and not from puppet. Investigate and potentially fix this.
# Note that our paging infrastructure (AQL as of 20161101) may need
# an update of it's sender whitelist. And don't forget to do an end-to-end
# test. That is submit a passive check of DOWN for a paging service and confirm
# people get the pages.
class icinga2(
    $enable_notifications  = 1,
    $enable_event_handlers = 1,
) {
    group { 'nagios':
        ensure    => present,
        name      => 'nagios',
        system    => true,
        allowdupe => false,
    }

    group { 'icinga2':
        ensure => present,
        name   => 'icinga2',
    }

    user { 'icinga2':
        name       => 'icinga2',
        home       => '/home/icinga2',
        gid        => 'icinga2',
        system     => true,
        managehome => false,
        shell      => '/bin/false',
        require    => [ Group['icinga2'], Group['nagios'] ],
        groups     => [ 'nagios' ],
    }

    package { 'icinga2':
        ensure => 'present',
    }

    file { '/etc/icinga2/conf.d/commands.conf':
        ensure => present,
        source => 'puppet:///modules/icinga2/commands.conf',
        owner  => 'root',
        group  => 'root',
        notify  => Base::Service_unit['icinga2'],
    }

    file { '/etc/icinga2/conf.d/groups.conf':
        ensure => present,
        source => 'puppet:///modules/icinga2/groups.conf',
        owner  => 'root',
        group  => 'root',
        notify  => Base::Service_unit['icinga2'],
    }

    file { '/etc/icinga2/conf.d/hosts.conf':
        ensure => present,
        source => 'puppet:///modules/icinga2/hosts.conf',
        owner  => 'root',
        group  => 'root',
        notify  => Base::Service_unit['icinga2'],
    }

    file { '/etc/icinga2/conf.d/notifications.conf':
        ensure => present,
        source => 'puppet:///modules/icinga2/notifications.conf',
        owner  => 'root',
        group  => 'root',
        notify  => Base::Service_unit['icinga2'],
    }

    file { '/etc/icinga2/conf.d/services.conf':
        ensure => present,
        source => 'puppet:///modules/icinga2/services.conf',
        owner  => 'root',
        group  => 'root',
    }

    file { '/etc/icinga2/conf.d/templates.conf':
        ensure => present,
        source => 'puppet:///modules/icinga2/templates.conf',
        owner  => 'root',
        group  => 'root',
        notify  => Base::Service_unit['icinga2'],
    }

    file { '/etc/icinga2/conf.d/timeperiods.conf':
        ensure => present,
        source => 'puppet:///modules/icinga2/timeperiods.conf',
        owner  => 'root',
        group  => 'root',
        notify  => Base::Service_unit['icinga2'],
    }

    file { '/etc/icinga2/conf.d/users.conf':
        ensure => present,
        source => 'puppet:///modules/icinga2/users.conf',
        owner  => 'root',
        group  => 'root',
        notify  => Base::Service_unit['icinga2'],
    }

    # Setup all plugins!
    class { '::icinga2::plugins':
        require => Package['icinga2'],
        notify  => Base::Service_unit['icinga2'],
    }

    # Fix the ownerships of some files. This is ugly but will do for now
    file { ['/var/cache/icinga2',
            '/var/lib/icinga2/',
        ]:
        ensure => directory,
        owner  => 'nagios',
        group  => 'nagios',
    }

    file { '/var/run/icinga2/':
        ensure => directory,
        owner  => 'nagios',
        group  => 'www-data',
    }

    base::service_unit { 'icinga2':
        ensure         => 'present',
        systemd        => true,
        upstart        => false,
        sysvinit       => true,
        service_params => {
            ensure     => 'running',
            provider   => $::initsystem,
            hasrestart => true,
            restart   => '/bin/systemctl reload icinga2',
        },
    }

    # FIXME: This should not require explicit setup
    # service { 'icinga2':
    #    ensure    => running,
    #    hasstatus => false,
    #    restart   => '/etc/init.d/icinga reload',
    #    require   => [
    #        Mount['/var/icinga-tmpfs'],
    #        File['/etc/init.d/icinga'],
    #    ],
    #}

    # Command folders / files to let icinga web to execute commands
    # See Debian Bug 571801
    file { '/var/run/icinga2/cmd':
        owner => 'nagios',
        group => 'www-data',
        mode  => '2710', # The sgid bit means new files inherit guid
    }

    # ensure icinga can write logs for ircecho, raid_handler etc.
    file { '/var/log/icinga2':
        ensure => 'directory',
        owner  => 'nagios',
        group  => 'www-data',
        mode   => '2755',
    }

    # Purge unmanaged nagios_host and nagios_services resources
    # This will only happen for non exported resources, that is resources that
    # are declared by the icinga host itself
    resources { 'nagios_host': purge => true, }
    resources { 'nagios_service': purge => true, }
}
