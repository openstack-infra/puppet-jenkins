class { '::jenkins::slave':
  user => true
}

class { '::jenkins::job_builder':
  url                         => 'https://ubuntu',
  username                    => 'jenkins',
  password                    => 'secret',
  jenkins_jobs_update_timeout => 1200,
  config_dir                  => '/etc/project-config/jenkins',
  require                     => Class['::jenkins::slave'],
}
