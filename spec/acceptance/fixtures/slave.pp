class { '::jenkins::slave':
  ssh_key => '',
  user    => false,
}

#FIXME: Test the jenkins::job_builder class
