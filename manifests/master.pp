# == Class: jenkins::master
#
class jenkins::master(
  $logo = '',
  $vhost_name = $::fqdn,
  $serveradmin = "webmaster@${::fqdn}",
  $ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $jenkins_ssh_private_key = '',
  $jenkins_ssh_public_key = '',
) {
  include pip
  include ::httpd

  case $::osfamily {
    'RedHat': {
      yumrepo { "Jenkins":
        baseurl => "http://pkg.jenkins-ci.org/redhat-stable/",
        descr => "Jenkins",
        enabled => 1,
        gpgcheck => 0
      }
      package { 'jenkins':
        ensure  => present,
        require => yumrepo['Jenkins'],
      }
      $packages = [
        'python-babel',
        'java-1.8.0-openjdk',
        'python-sqlalchemy',  # devstack-gate
        'sqlite', # interact with devstack-gate DB
      ]
      # Needed to allow mod_proxy to forward on local Jenkins TCP port
      exec { 'enable selinux httpd_can_network_connect':
        path        => '/bin:/usr/bin:/usr/sbin',
        command     => 'setsebool -P httpd_can_network_connect true',
        onlyif      => 'getsebool httpd_can_network_connect | egrep "off$"'
      }
    }
    'Debian': {
      include apt
      package { 'openjdk-7-jre-headless':
        ensure => present,
      }

      package { 'openjdk-6-jre-headless':
        ensure  => purged,
        require => Package['openjdk-7-jre-headless'],
      }

      apt::source { 'jenkins':
        location    => 'http://pkg.jenkins-ci.org/debian-stable',
        release     => 'binary/',
        repos       => '',
        key         => {
          'id'     => 'D50582E6',
          'source' => 'http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key',
        },
        require     => [
          Package['openjdk-7-jre-headless'],
        ],
        include_src => false,
      }
      if ! defined(Httpd_mod['rewrite']) {
        httpd_mod { 'rewrite':
          ensure => present,
        }
      }
      if ! defined(Httpd_mod['proxy']) {
        httpd_mod { 'proxy':
          ensure => present,
        }
      }
      if ! defined(Httpd_mod['proxy_http']) {
        httpd_mod { 'proxy_http':
          ensure => present,
        }
      }
      if ! defined(Httpd_mod['headers']) {
        httpd_mod { 'headers':
          ensure => present,
        }
      }
      $packages = [
        'python-babel',
        'python-sqlalchemy',  # devstack-gate
        'ssl-cert',
        'sqlite3', # interact with devstack-gate DB
      ]
      package { 'jenkins':
        ensure  => present,
        require => Apt::Source['jenkins'],
      }
      exec { 'update apt cache':
        subscribe   => File['/etc/apt/sources.list.d/jenkins.list'],
        refreshonly => true,
        path        => '/bin:/usr/bin',
        command     => 'apt-get update',
      }
    }
  }


  ::httpd::vhost { $vhost_name:
    port     => 443,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'jenkins/jenkins.vhost.erb',
    ssl      => true,
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      require => Package['ssl-cert'],
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  package { $packages:
    ensure => present,
  }

  file { '/etc/default/jenkins':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/jenkins/jenkins.default',
  }

  file { '/var/lib/jenkins':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'adm',
    require => Package['jenkins'],
  }

  file { '/var/lib/jenkins/.ssh/':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => $jenkins_ssh_private_key,
    replace => true,
    require => File['/var/lib/jenkins/.ssh/'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa.pub':
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    content => "ssh_rsa ${jenkins_ssh_public_key} jenkins@${::fqdn}",
    replace => true,
    require => File['/var/lib/jenkins/.ssh/'],
  }

  file { '/var/lib/jenkins/plugins':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0750',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['/var/lib/jenkins/plugins'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin/openstack.css':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    source  => 'puppet:///modules/jenkins/openstack.css',
    require => File['/var/lib/jenkins/plugins/simple-theme-plugin'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin/openstack.js':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    content => template('jenkins/openstack.js.erb'),
    require => File['/var/lib/jenkins/plugins/simple-theme-plugin'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin/openstack-page-bkg.jpg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    source  => 'puppet:///modules/jenkins/openstack-page-bkg.jpg',
    require => File['/var/lib/jenkins/plugins/simple-theme-plugin'],
  }

  file { '/var/lib/jenkins/logger.conf':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    source  => 'puppet:///modules/jenkins/logger.conf',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin/title.png':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    source  => "puppet:///modules/jenkins/${logo}",
    require => File['/var/lib/jenkins/plugins/simple-theme-plugin'],
  }

  file { '/usr/local/jenkins':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
