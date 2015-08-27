class { '::jenkins::master':
  vhost_name              => 'localhost',
  jenkins_ssh_private_key => file('/tmp/jenkins-ssh-keys/ssh_rsa_key'),
  jenkins_ssh_public_key  => file('/tmp/jenkins-ssh-keys/ssh_rsa_key.pub'),
} -> class { '::jenkins::job_builder':
  url                         => 'https://localhost',
  username                    => 'jenkins',
  password                    => 'secret',
  jenkins_jobs_update_timeout => 1200,
  config_dir                  => '/etc/project-config/jenkins'
}
