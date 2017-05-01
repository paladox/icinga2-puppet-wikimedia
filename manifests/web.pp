# = Class: icinga2::web
#
# Sets up an apache instance for icinga web interface,
# protected with ldap authentication
class icinga2::web {
    include ::icinga2

    # Apparently required for the web interface
    package { 'icinga2-doc':
        ensure => present,
    }
    include ::apache
    include ::apache::mod::php5
    include ::apache::mod::ssl
    include ::apache::mod::headers
    include ::apache::mod::cgi

    ferm::service { 'icinga2-https':
      proto => 'tcp',
      port  => 443,
    }
    ferm::service { 'icinga2-http':
      proto => 'tcp',
      port  => 80,
    }

    require_package('php5')
    require_package('php5-dev')
    require_package('php5-gd')

    include ::passwords::ldap::wmf_cluster
    $proxypass = $passwords::ldap::wmf_cluster::proxypass

    file { '/usr/share/icinga/htdocs/images/logos/ubuntu.png':
        source => 'puppet:///modules/icinga/ubuntu.png',
        owner  => 'icinga2',
        group  => 'icinga2',
        mode   => '0644',
    }

    # install the Icinga Apache site
    include ::apache::mod::rewrite
    include ::apache::mod::authnz_ldap

    $ssl_settings = ssl_ciphersuite('apache', 'mid', true)

    letsencrypt::cert::integrated { 'icinga2':
        subjects   => hiera hiera('icinga2_apache_host', 'icinga2.wmflabs.org'),
        puppet_svc => 'apache2',
        system_svc => 'apache2',
        require    => Class['apache::mod::ssl'],
    }

    apache::site { 'icinga2.wmflabs.org':
        content => template('icinga/icinga2.wmflabs.org.erb'),
    }

    # remove icinga2 default config
    file { '/etc/icinga/apache2.conf':
        ensure => absent,
    }
    file { '/etc/apache2/conf.d/icinga2.conf':
        ensure => absent,
    }

}
