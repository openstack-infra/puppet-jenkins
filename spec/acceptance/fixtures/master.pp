class { '::jenkins::jenkinsuser':
  ssh_key => 'sshkey',
}

class { '::jenkins::master':
  vhost_name              => '127.0.0.1',
  jenkins_ssh_private_key => file('/tmp/jenkins-ssh-keys/ssh_rsa_key'),
  jenkins_ssh_public_key  => file('/tmp/jenkins-ssh-keys/ssh_rsa_key.pub'),
  require                 => Class['::jenkins::jenkinsuser'],
}

class { '::jenkins::job_builder':
  url                         => 'https://127.0.0.1',
  username                    => 'jenkins',
  password                    => 'secret',
  jenkins_jobs_update_timeout => 1200,
  config_dir                  => '/etc/project-config/jenkins',
  require                     => Class['::jenkins::master'],
}
