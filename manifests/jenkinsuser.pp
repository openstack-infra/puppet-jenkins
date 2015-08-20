# == Class: jenkins::jenkinsuser
#
class jenkins::jenkinsuser(
  $ssh_key,
  $ensure = present,
  $gitfullname = 'OpenStack Jenkins',
  $gitemail = 'jenkins@openstack.org',
  $gerrituser = 'jenkins',
) {

  group { 'jenkins':
    ensure => present,
  }

  user { 'jenkins':
    ensure     => present,
    comment    => 'Jenkins User',
    home       => '/home/jenkins',
    gid        => 'jenkins',
    shell      => '/bin/bash',
    membership => 'minimum',
    groups     => [],
    require    => Group['jenkins'],
  }

  file { '/home/jenkins':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    require => User['jenkins'],
  }

  file { '/home/jenkins/.pip':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.gitconfig':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => template('jenkins/gitconfig.erb'),
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.ssh':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File['/home/jenkins'],
  }

  # cleanup old content in directory
  file { '/home/jenkins/.ssh/authorized_keys':
    ensure  => 'file',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    content => template('jenkins/authorized_keys.erb'),
    require => File['/home/jenkins/.ssh'],
  }

  #NOTE: not all distributions have default bash files in /etc/skel
  if ($::osfamily == 'Debian') {

    file { '/home/jenkins/.bashrc':
      ensure  => present,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      source  => '/etc/skel/.bashrc',
      replace => false,
      require => File['/home/jenkins'],
    }

    file { '/home/jenkins/.bash_logout':
      ensure  => present,
      source  => '/etc/skel/.bash_logout',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      replace => false,
      require => File['/home/jenkins'],
    }

    file { '/home/jenkins/.profile':
      ensure  => present,
      source  => '/etc/skel/.profile',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      replace => false,
      require => File['/home/jenkins'],
    }

  }

  file { '/home/jenkins/.ssh/config':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    require => File['/home/jenkins/.ssh'],
    source  => 'puppet:///modules/jenkins/ssh_config',
  }

  file { '/home/jenkins/.gnupg':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0700',
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.gnupg/pubring.gpg':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0600',
    require => File['/home/jenkins/.gnupg'],
    source  => 'puppet:///modules/jenkins/pubring.gpg',
  }

  file { '/home/jenkins/.config':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.m2':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0755',
    require => File['/home/jenkins'],
  }

  file { '/home/jenkins/.m2/settings.xml':
    ensure  => present,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    require => File['/home/jenkins/.m2'],
    source  => 'puppet:///modules/jenkins/settings.xml',
  }

}
