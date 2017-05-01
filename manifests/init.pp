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
        name   => 'icinga',
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

    file { '/etc/icinga/cgi.cfg':
        source  => 'puppet:///modules/icinga/cgi.cfg',
        owner   => 'icinga',
        group   => 'icinga',
        mode    => '0644',
        require => Package['icinga'],
        notify  => Service['icinga'],
    }

    file { '/etc/icinga2/icinga2.conf':
        content => template('icinga/icinga.cfg.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['icinga2'],
        notify  => Service['icinga2'],
    }

    file { '/etc/icinga2/nsca_frack.cfg':
        content => secret('nagios/nsca_frack.cfg'),
        owner   => 'icinga2',
        group   => 'icinga2',
        mode    => '0644',
        require => Package['icinga2'],
        notify  => Service['icinga2'],
    }

    class { '::nagios_common::contactgroups':
        source  => 'puppet:///modules/nagios_common/contactgroups.cfg',
        require => Package['icinga2'],
        notify  => Service['icinga2'],
    }

    class { '::nagios_common::contacts':
        content => secret('nagios/contacts.cfg'),
        require => Package['icinga2'],
        notify  => Service['icinga2'],
    }

    class { [
      '::nagios_common::user_macros',
      '::nagios_common::timeperiods',
      '::nagios_common::notification_commands',
    ] :
        require => Package['icinga2'],
        notify  => Service['icinga2'],
    }

    # FIXME: This should be in the package?
    logrotate::conf { 'icinga2':
        ensure => present,
        source => 'puppet:///modules/icinga2/logrotate.conf',
    }

    # Setup all plugins!
    class { '::icinga2::plugins':
        require => Package['icinga2'],
        notify  => Service['icinga2'],
    }

    # Setup tmpfs for use by icinga
    file { '/var/icinga2-tmpfs':
        ensure => directory,
        owner  => 'icinga2',
        group  => 'icinga2',
        mode   => '0755',
    }

    mount { '/var/icinga2-tmpfs':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'tmpfs',
        device  => 'none',
        options => 'size=128m,uid=icinga,gid=icinga2,mode=755',
        require => File['/var/icinga2-tmpfs'],
    }
    # Fix the ownerships of some files. This is ugly but will do for now
    file { ['/var/cache/icinga2',
            '/var/lib/icinga2/',
        ]:
        ensure => directory,
        owner  => 'nagios',
        group  => 'nagios',
    }

    file { ['/var/run/icinga2/',
            '/var/run/icinga2/cmd',
        ]:
        ensure => directory,
        owner  => 'nagios',
        group  => 'www-data',
    }

    base::service_unit { 'icinga2':
        ensure         => 'present',
        systemd        => true,
        upstart        => false,
        sysvinit       => true,
        require   => [
            Mount['/var/icinga2-tmpfs'],
        ],
        service_params => {
            ensure     => 'running',
            provider   => $::initsystem,
            hasrestart => true,
            restart   => 'systemctl reload icinga2',
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

    # Script to purge resources for non-existent hosts
    file { '/usr/local/sbin/purge-nagios-resources.py':
        source => 'puppet:///modules/icinga2/purge-nagios-resources.py',
        owner  => 'icinga2',
        group  => 'icinga2',
        mode   => '0755',
    }

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
        group  => 'nagios',
        mode   => '2755',
    }

    # Check that the icinga config is sane
    # This may not work for icinga2 yet.
    monitoring::service { 'check_icinga2_config':
        description    => 'Check correctness of the icinga2 configuration',
        check_command  => 'check_icinga2_config',
        check_interval => 10,
    }

    # script to schedule host downtimes
    file { '/usr/local/bin/icinga-downtime':
        ensure => present,
        source => 'puppet:///modules/icinga/icinga-downtime.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0550',
    }
    # Purge unmanaged nagios_host and nagios_services resources
    # This will only happen for non exported resources, that is resources that
    # are declared by the icinga host itself
    resources { 'nagios_host': purge => true, }
    resources { 'nagios_service': purge => true, }
}
