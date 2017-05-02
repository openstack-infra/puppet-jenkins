# == Class: jenkins::master
#
# This class will install and configure Jenkins master
#
# === Parameters
#
# [*jenkins_default*]
#   (Optional) Puppet source from which to initialize /etc/defaults/jenkins.
#   E.g. 'puppet:///modules/<yourmodule/jenkins.default'. If specified,
#   java_args_override, run_standalone, max_open_files, and http_port are
#   ignored.

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
  $jenkins_default = undef,
  $jenkins_version = 'present',
  $java_args_override = undef,
  $jenkins_deb_url_base = 'http://pkg.jenkins.io/debian/binary',
  $run_standalone = true,
  $max_open_files = 8192,
  $http_port = 8080,
) {
  include ::pip
  include ::apt
  include ::httpd

  case $::osfamily {
    'Debian': {
      if ($::operatingsystem == 'Ubuntu') and ($::operatingsystemrelease >= '16.04') {
        $jdk_package = 'openjdk-8-jre-headless'
        $jdk_low_package = 'openjdk-7-jre-headless'
      } else {
        $jdk_package = 'openjdk-7-jre-headless'
        $jdk_low_package = 'openjdk-6-jre-headless'
      }
    }
    default: {
      $jdk_package = 'openjdk-7-jre-headless'
      $jdk_low_package = 'openjdk-6-jre-headless'
    }
  }

  package { $jdk_package:
    ensure => present,
  }

  package { $jdk_low_package:
    ensure  => purged,
    require => Package[$jdk_package],
  }

  apt::source { 'jenkins':
    location    => 'http://pkg.jenkins.io/debian-stable',
    release     => 'binary/',
    repos       => '',
    key         => {
      'id'     => 'D50582E6',
      'source' => 'http://pkg.jenkins.io/debian-stable/jenkins.io.key',
    },
    require     => [
      Package[$jdk_package],
    ],
    include_src => false,
  }

  ::httpd::vhost { $vhost_name:
    port     => 443,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'jenkins/jenkins.vhost.erb',
    ssl      => true,
  }
  if ! defined(Httpd::Mod['rewrite']) {
    httpd::mod { 'rewrite':
      ensure => present,
    }
  }
  if ! defined(Httpd::Mod['proxy']) {
    httpd::mod { 'proxy':
      ensure => present,
    }
  }
  if ! defined(Httpd::Mod['proxy_http']) {
    httpd::mod { 'proxy_http':
      ensure => present,
    }
  }
  if ! defined(Httpd::Mod['headers']) {
    httpd::mod { 'headers':
      ensure => present,
    }
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

  $packages = [
    'python-babel',
    'python-sqlalchemy',  # devstack-gate
    'ssl-cert',
    'sqlite3', # interact with devstack-gate DB
  ]

  package { $packages:
    ensure => present,
  }

  # jenkins apt-repo doesn't offer multiple versions
  # so if anything other than 'present' or 'latest'
  # is set, pull down the .deb using wget
  # and install via the dpkg resource
  if ($jenkins_version == 'present') or
      ($jenkins_version == 'latest')
  {
    package { 'jenkins':
      ensure  => $jenkins_version,
      require => Apt::Source['jenkins'],
    }
  } else {
    $jenkins_deb = "jenkins_${jenkins_version}_all.deb"
    $jenkins_deb_url = "${jenkins_deb_url_base}/${jenkins_deb}"
    $jenkins_deb_tmp = "/var/tmp/${jenkins_deb}"

    archive { 'jenkins_deb':
      source => $jenkins_deb_url,
      path   => $jenkins_deb_tmp,
    }

    # required by jenkins.deb, but as we're not using apt,
    # no dependency resolution is performed.
    package { 'daemon': }

    package { 'jenkins':
      # for the dpkg provider, latest means check the version,
      # installed/present skips the version check, we want to version
      # check so that we can move between versions using puppet
      ensure   => latest,
      provider => dpkg,
      source   => $jenkins_deb_tmp,
      require  => [Package['daemon'], Archive['jenkins_deb']],
    }
  }

  exec { 'update apt cache':
    subscribe   => File['/etc/apt/sources.list.d/jenkins.list'],
    refreshonly => true,
    path        => '/bin:/usr/bin',
    command     => 'apt-get update',
  }

  # Template uses:
  # - $java_args_override
  # - $run_standalone
  # - $max_open_files
  # - $http_port
  if ! $jenkins_default {
    file { '/etc/default/jenkins':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('jenkins/jenkins.default.erb'),
    }
  } else {
    file { '/etc/default/jenkins':
      ensure => present,
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => $jenkins_default
    }
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

  file { '/var/lib/jenkins/init.groovy.d':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['/var/lib/jenkins'],
  }

  file { '/var/lib/jenkins/init.groovy.d/cli-shutdown.groovy':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    source  => 'puppet:///modules/jenkins/cli-shutdown.groovy',
    require => File['/var/lib/jenkins/init.groovy.d'],
  }

  file { '/usr/local/jenkins':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # Jenkins management utility scripts
  if ! defined(Package['python-jenkins']) {
    package { 'python-jenkins':
      ensure   => latest,
      provider => openstack_pip,
    }
  }

  file { '/usr/local/jenkins/bin':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/usr/local/jenkins/bin/safe_jenkins_shutdown':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/jenkins/safe_jenkins_shutdown',
  }
}
