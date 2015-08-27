class { '::jenkins::slave':
  ssh_key => 'sshkey',
  user    => true
}
