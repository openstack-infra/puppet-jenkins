class { '::jenkins::slave':
  ssh_key => 'sshkey',
  user    => true
}

class { '::jenkins::job_builder':
  url                         => 'https://127.0.0.1',
  username                    => 'jenkins',
  password                    => 'secret',
  jenkins_jobs_update_timeout => 1200,
  config_dir                  => '/etc/project-config/jenkins',
  require                     => Class['::jenkins::slave'],
}
