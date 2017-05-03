require 'spec_helper_acceptance'

describe 'puppet-jenkins slave module', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def preconditions_puppet_module
    module_path = File.join(pp_path, 'preconditions.pp')
    File.read(module_path)
  end

  def default_password
    command('/bin/cat /var/lib/jenkins/secrets/initialAdminPassword').stdout.chomp
  end

  def jenkins_slave_puppet_module
    module_path = File.join(pp_path, 'slave.pp')
    File.read(module_path).gsub('<<jenkins_default_password>>', default_password)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  it 'should work with no errors' do
    apply_manifest(jenkins_slave_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(jenkins_slave_puppet_module, catch_changes: true)
  end

  it 'debug' do
    require 'base64'
    pw = Base64.strict_encode64("admin:#{default_password}")
    hdr = "Basic #{pw}"
    r = command("/usr/bin/curl \"https://`hostname`/pluginManager/api/json?depth=2\" -H 'Authorization: #{hdr}'")
    puts r.stdout
    puts r.stderr
  end
  it 'debug2' do
    r = command("/usr/bin/openssl s_client -connect `hostname`:443")
    puts r.stdout
    puts r.stderr
  end
end
