# Class: jenkins::params
#
# This class holds parameters that need to be
# accessed by other classes.
class jenkins::params {
  case $::osfamily {
    'RedHat': {
      #yum groupinstall "Development Tools"
      # common packages
      if ($::operatingsystem == 'Fedora') and (versioncmp($::operatingsystemrelease, '21') >= 0) {
        $jdk_package = 'java-1.8.0-openjdk-devel'
      } else {
        $jdk_package = 'java-1.7.0-openjdk-devel'
      }
      $ccache_package = 'ccache'
      $python_netaddr_package = 'python-netaddr'
      # FIXME: No Maven packages on RHEL
      #$maven_package = 'maven'
      $cgroups_package = 'libcgroup'
      if ($::operatingsystem == 'Fedora') and (versioncmp($::operatingsystemrelease, '19') >= 0) {
        $cgroups_tools_package = 'libcgroup-tools'
        $cgconfig_require = [
          Package['cgroups'],
          Package['cgroups-tools'],
        ]
        $cgred_require = [
          Package['cgroups'],
          Package['cgroups-tools'],
        ]
      } else {
        $cgroups_tools_package = ''
        $cgconfig_require = Package['cgroups']
        $cgred_require = Package['cgroups']
      }
    }
    'Suse': {
      $jdk_package = 'java-1_8_0-openjdk-devel'
      $ccache_package = 'ccache'
      $python_netaddr_package = 'python-netaddr'
      $cgroups_package = 'libcgroup'
      $cgroups_tools_package = 'libcgroup-tools'
      $cgconfig_require = [
        Package['libcgroup-tools']
      ]
      $cgred_require = [
        Package['libcgroup-tools']
      ]
    }
    'Debian': {
      # common packages
      $ccache_package = 'ccache'
      $python_netaddr_package = 'python-netaddr'
      if ($::operatingsystem == 'Ubuntu') and ($::operatingsystemrelease >= '16.04') {
        $jdk_package = 'openjdk-8-jdk'
        $maven_package = 'maven'
      } else {
        $jdk_package = 'openjdk-7-jdk'
        $maven_package = 'maven2'
      }
      $cgroups_package = 'cgroup-bin'
      $cgroups_tools_package = ''
      $cgconfig_require = [
        Package['cgroups'],
        File['cgconfig.service'],
      ]
      $cgred_require = [
        Package['cgroups'],
        File['cgred.service'],
      ]
      # ruby packages
      # ruby1.9.1 is not present in Debian Jessie, use ruby instead
      if ($::operatingsystem == 'Debian' or $::lsbdistcodename == 'xenial') {
        $ruby_package = 'ruby'
        $ruby_dev_package = 'ruby-dev'
      }
      else {
        $ruby_package = 'ruby1.9.1'
        $ruby_dev_package = 'ruby1.9.1-dev'
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'jenkins' module only supports osfamily Debian or RedHat/Suse (slaves only).")
    }
  }
}
