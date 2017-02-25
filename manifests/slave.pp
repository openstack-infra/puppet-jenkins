# == Class: jenkins::slave
#
class jenkins::slave(
  $ssh_key,
  $user = true,
  $gitfullname = 'OpenStack Jenkins',
  $gitemail = 'jenkins@openstack.org',
  $gitpgpkey = 'jenkins@openstack.org',
  $gerrituser = 'jenkins',
  $gerritkeytype = 'rsa',
  $gerritkey = undef,
) {

  include ::haveged
  include ::pip
  include ::jenkins::params

  if ($user == true) {
    class { '::jenkins::jenkinsuser':
      ensure        => present,
      ssh_key       => $ssh_key,
      gitfullname   => $gitfullname,
      gitemail      => $gitemail,
      gitpgpkey     => $gitpgpkey,
      gerrituser    => $gerrituser,
      gerritkeytype => $gerritkeytype,
      gerritkey     => $gerritkey,
    }
  }

  anchor { 'jenkins::slave::update-java-alternatives': }

  # Packages that all jenkins slaves need
  $packages = [
    $::jenkins::params::jdk_package, # jdk for building java jobs
    $::jenkins::params::ccache_package,
    $::jenkins::params::python_netaddr_package, # Needed for devstack address_in_net()
  ]

  file { '/etc/apt/sources.list.d/cloudarchive.list':
    ensure => absent,
  }

  package { $packages:
    ensure => present,
    before => Anchor['jenkins::slave::update-java-alternatives']
  }

  case $::osfamily {
    'RedHat': {
      exec { 'yum Group Install':
        unless  => '/usr/bin/yum grouplist "Development tools" | /bin/grep "^Installed [Gg]roups"',
        command => '/usr/bin/yum -y groupinstall "Development tools"',
        timeout => 1800,
      }

      if ($::operatingsystem != 'Fedora') {
        exec { 'update-java-alternatives':
          unless  => '/bin/ls -l /etc/alternatives/java | /bin/grep 1.7.0-openjdk',
          command => '/usr/sbin/alternatives --set java /usr/lib/jvm/jre-1.7.0-openjdk.x86_64/bin/java && /usr/sbin/alternatives --set javac /usr/lib/jvm/java-1.7.0-openjdk.x86_64/bin/javac',
          require => Anchor['jenkins::slave::update-java-alternatives']
        }
      }
    }
    'Suse': {
      exec { 'zypper devel pattern install':
        unless  => '/usr/bin/zypper -n info -t pattern devel_basis | /bin/grep -q "Installed.*yes"',
        command => '/usr/bin/zypper -n in -t pattern devel_basis',
        timeout => 1800,
      }
    }
    'Debian': {
      # install build-essential package group
      package { 'build-essential':
        ensure => present,
      }

      package { $::jenkins::params::maven_package:
        ensure  => present,
        require => Package[$::jenkins::params::jdk_package],
      }

      package { $::jenkins::params::ruby_package:
        ensure => present,
      }

      package { $::jenkins::params::ruby_dev_package:
        ensure => present,
      }

      package { 'openjdk-6-jre-headless':
        ensure  => purged,
        require => Package[$::jenkins::params::jdk_package],
      }

      if ($::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '16.04') < 0) {
        exec { 'update-java-alternatives':
          unless  => "/bin/ls -l /etc/alternatives/java | /bin/grep java-7-openjdk-${::dpkg_arch}",
          command => "/usr/sbin/update-java-alternatives --set java-1.7.0-openjdk-${::dpkg_arch}",
          require => Anchor['jenkins::slave::update-java-alternatives']
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'jenkins' module only supports osfamily Debian or RedHat/Suse (slaves only).")
    }
  }

  package { 'tox':
    ensure   => 'latest',
    provider => openstack_pip,
    require  => Class[pip],
  }

  # TODO(fungi): switch jobs to use /usr/git-review-env/bin/git-review
  package { 'git-review':
    ensure   => '1.25.0',
    provider => openstack_pip,
    require  => Class[pip],
  }

  file { '/usr/local/bin/gcc':
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { '/usr/local/bin/g++':
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { '/usr/local/bin/cc':
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { '/usr/local/bin/c++':
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { "/usr/local/bin/${::hardwareisa}-linux-gnu-gcc":
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { "/usr/local/bin/${::hardwareisa}-linux-gnu-g++":
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { "/usr/local/bin/${::hardwareisa}-linux-gnu-cc":
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { "/usr/local/bin/${::hardwareisa}-linux-gnu-c++":
    ensure  => link,
    target  => '/usr/bin/ccache',
    require => Package['ccache'],
  }

  file { '/usr/local/jenkins':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

}
