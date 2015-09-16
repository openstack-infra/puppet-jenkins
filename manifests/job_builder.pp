# == Class: jenkins::job_builder
#
class jenkins::job_builder (
  $url,
  $username,
  $password,
  $git_revision = 'master',
  $git_url = 'https://git.openstack.org/openstack-infra/jenkins-job-builder',
  $config_dir = '',
  $jenkins_jobs_update_timeout = '600',
  $extensions = [],
) {
  validate_array($extensions)

  # A lot of things need yaml, be conservative requiring this package to avoid
  # conflicts with other modules.
  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
  }

  if ! defined(Package['python-jenkins']) {
    package { 'python-jenkins':
      ensure   => present,
      provider => 'pip',
    }
  }

  vcsrepo { '/opt/jenkins_job_builder':
    ensure   => latest,
    provider => git,
    revision => $git_revision,
    source   => $git_url,
  }

  exec { 'install_jenkins_job_builder':
    command     => 'pip install /opt/jenkins_job_builder',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/jenkins_job_builder'],
  }

  file { '/etc/jenkins_jobs':
    ensure => directory,
  }

  file { '/etc/jenkins_jobs/config':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    source  => $config_dir,
    require => File['/etc/jenkins_jobs'],
    notify  => Exec['jenkins_jobs_update'],
  }

  exec { 'jenkins_jobs_update':
    command     => 'jenkins-jobs update --delete-old /etc/jenkins_jobs/config',
    timeout     => $jenkins_jobs_update_timeout,
    path        => '/bin:/usr/bin:/usr/local/bin',
    refreshonly => true,
    require     => [
      File['/etc/jenkins_jobs/jenkins_jobs.ini'],
      Package['python-jenkins'],
      Package['python-yaml'],
    ],
  }

# TODO: We should put in  notify Exec['jenkins_jobs_update']
#       at some point, but that still has some problems.
  file { '/etc/jenkins_jobs/jenkins_jobs.ini':
    ensure  => present,
    mode    => '0400',
    content => template('jenkins/jenkins_jobs.ini.erb'),
    require => File['/etc/jenkins_jobs'],
  }
}
