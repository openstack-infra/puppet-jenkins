class { '::jenkins::jenkinsuser':
  ssh_key => 'sshkey',
}

class { '::jenkins::master':
  vhost_name              => '127.0.0.1',
  jenkins_ssh_private_key => file('/tmp/jenkins-ssh-keys/ssh_rsa_key'),
  jenkins_ssh_public_key  => file('/tmp/jenkins-ssh-keys/ssh_rsa_key.pub'),
  require                 => Class['::jenkins::jenkinsuser'],
}
