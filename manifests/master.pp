# == Class: jenkins::master
#
class jenkins::master(
  $logo = '',
  $vhost_name = $::fqdn,
  $serveradmin = "webmaster@${::fqdn}",
  $ssl_cert_file = '',
  $ssl_key_file = '',
  $ssl_chain_file = '',
  $ssl_cert_file_contents = '', # If left empty puppet will not create file.
  $ssl_key_file_contents = '', # If left empty puppet will not create file.
  $ssl_chain_file_contents = '', # If left empty puppet will not create file.
  $jenkins_ssh_private_key = '',
  $jenkins_ssh_public_key = '',
  $install_method = 'apt', # do dpkg or apt install of jenkins
  $install_repo   = 'http://pkg.jenkins-ci.org/debian-stable', # repo to use
) {
  include pip
  include apt
  include apache
  case $install_method {
    /^apt$/: {
      # install using apt provider, default
      #This key is at http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key
      apt::key { 'jenkins':
        key        => 'D50582E6',
        key_source => "${install_repo}/jenkins-ci.org.key",
      }
      apt::source { 'jenkins':
        location    => $install_repo,
        release     => 'binary/',
        repos       => '',
        require     => [
          Apt::Key['jenkins'],
          Package['openjdk-7-jre-headless'],
        ],
        include_src => false,
      }
      exec { 'update apt cache':
        subscribe   => File['/etc/apt/sources.list.d/jenkins.list'],
        refreshonly => true,
        path        => '/bin:/usr/bin',
        command     => 'apt-get update',
      }
      package { 'jenkins':
        ensure  => present,
        require => Apt::Source['jenkins'],
      }
    /^dpkg$/: {
      # install using dpk provider, example, install_rep =>
      # http://pkg.jenkins-ci.org/debian-stable/binary/jenkins_1.565.3_all.deb
      # to try it , setup hiera values for it.
      exec { 'jenkins_dpkg_file':
        path    => '/bin:/usr/bin',
        command => "curl -s -k -L ${install_repo} > /tmp/jenkins-download.deb",
        creates => '/tmp/jenkins-download.deb',
      }
      package { 'jenkins':
        ensure   => $jenkins_version,
        provider => dpkg,
        source   => '/tmp/jenkins-download.deb',
        require  => [
          Exec['jenkins_dpkg_file'],
          Package['openjdk-7-jre-headless'],
        ],
      }
    }
    default: {
      fail("install_method is ${install_method}, invalid.  use apt or dpkg.")
    }
  }
  package { 'openjdk-7-jre-headless':
    ensure => present,
  }

  package { 'openjdk-6-jre-headless':
    ensure  => purged,
    require => Package['openjdk-7-jre-headless'],
  }

  apache::vhost { $vhost_name:
    port     => 443,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'jenkins/jenkins.vhost.erb',
    ssl      => true,
  }
  if ! defined(A2mod['rewrite']) {
    a2mod { 'rewrite':
      ensure => present,
    }
  }
  if ! defined(A2mod['proxy']) {
    a2mod { 'proxy':
      ensure => present,
    }
  }
  if ! defined(A2mod['proxy_http']) {
    a2mod { 'proxy_http':
      ensure => present,
    }
  }
  if ! defined(A2mod['headers']) {
    a2mod { 'headers':
      ensure => present,
    }
  }

  if $ssl_cert_file_contents != '' {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != '' {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      require => Package['ssl-cert'],
      before  => Apache::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != '' {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Apache::Vhost[$vhost_name],
    }
  }

  $packages = [
    'python-babel',
    'python-sqlalchemy',  # devstack-gate
    'ssl-cert',
    'sqlite3', # interact with devstack-gate DB
  ]

  package { $packages:
    ensure => present,
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
    group   => 'nogroup',
    mode    => '0700',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa':
    owner   => 'jenkins',
    group   => 'nogroup',
    mode    => '0600',
    content => $jenkins_ssh_private_key,
    replace => true,
    require => File['/var/lib/jenkins/.ssh/'],
  }

  file { '/var/lib/jenkins/.ssh/id_rsa.pub':
    owner   => 'jenkins',
    group   => 'nogroup',
    mode    => '0644',
    content => "ssh_rsa ${jenkins_ssh_public_key} jenkins@${::fqdn}",
    replace => true,
    require => File['/var/lib/jenkins/.ssh/'],
  }

  file { '/var/lib/jenkins/plugins':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'nogroup',
    mode    => '0750',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'nogroup',
    require => File['/var/lib/jenkins/plugins'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin/openstack.css':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'nogroup',
    source  => 'puppet:///modules/jenkins/openstack.css',
    require => File['/var/lib/jenkins/plugins/simple-theme-plugin'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin/openstack.js':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'nogroup',
    content => template('jenkins/openstack.js.erb'),
    require => File['/var/lib/jenkins/plugins/simple-theme-plugin'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin/openstack-page-bkg.jpg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'nogroup',
    source  => 'puppet:///modules/jenkins/openstack-page-bkg.jpg',
    require => File['/var/lib/jenkins/plugins/simple-theme-plugin'],
  }

  file { '/var/lib/jenkins/logger.conf':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'nogroup',
    source  => 'puppet:///modules/jenkins/logger.conf',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/plugins/simple-theme-plugin/title.png':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'nogroup',
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
