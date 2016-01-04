# == Class: jenkins::cli
#
class jenkins::cli (
  $base_folder = '/opt/jenkins',
  $dest_folder = 'cli',
) {
  file { $base_folder:
    ensure => directory,
  }

  file { "${base_folder}/${dest_folder}":
    ensure  => directory,
    require => File[$base_folder],
  }

  exec { 'download-cli':
    command => '/usr/bin/wget http://localhost:8080/jnlpJars/jenkins-cli.jar',
    cwd     => "${base_folder}/${dest_folder}",
    creates => "${base_folder}/${dest_folder}/jenkins-cli.jar",
    require => File["${base_folder}/${dest_folder}"],
    onlyif  => '/usr/sbin/service jenkins status',
  }
}
