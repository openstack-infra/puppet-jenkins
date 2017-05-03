class { '::jenkins::slave':
  ssh_key => 'sshkey',
  user    => true
}

#FIXME: Test the jenkins::job_builder class
