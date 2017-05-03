class { '::jenkins::jenkinsuser': }

class { '::jenkins::master':
  vhost_name              => 'ubuntu',
  jenkins_ssh_private_key => file('/tmp/jenkins-ssh-keys/ssh_rsa_key'),
  jenkins_ssh_public_key  => file('/tmp/jenkins-ssh-keys/ssh_rsa_key.pub'),
}
