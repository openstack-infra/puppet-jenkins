class jenkins_jobs($site, $projects) {
  file { '/usr/local/jenkins_jobs':
    owner => 'root',
    group => 'root',
    mode => 755,
    ensure => 'directory',
    recurse => true,
    source => ['puppet:///modules/jenkins_jobs/']
  }

  file { '/usr/local/jenkins_jobs/jenkins_jobs.ini':
    owner => 'root',
    group => 'root',
    mode => 440,
    ensure => 'present',
    source => 'file:///root/secret-files/jenkins_jobs.ini',
    replace => 'true',
    require => File['/usr/local/jenkins_jobs']
  }

  process_projects { $projects:
    site => $site,
    require => [
      File['/usr/local/jenkins_jobs/jenkins_jobs.ini'],
      Package['python-jenkins']
      ]
  }

  package { "python-pip":
    ensure => present
  }

  package { "python-jenkins":
    ensure => latest,
    provider => pip,
    require => Package[python-pip],
  }

}
