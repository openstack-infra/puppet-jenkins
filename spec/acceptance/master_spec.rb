require 'spec_helper_acceptance'

describe 'puppet-jenkins master module', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  def pp_path
    base_path = File.dirname(__FILE__)
    File.join(base_path, 'fixtures')
  end

  def preconditions_puppet_module
    module_path = File.join(pp_path, 'preconditions.pp')
    File.read(module_path)
  end

  def jenkins_master_puppet_module
    module_path = File.join(pp_path, 'master.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  it 'should work with no errors' do
    apply_manifest(jenkins_master_puppet_module, catch_failures: true)
  end

  it 'should be idempotent' do
    apply_manifest(jenkins_master_puppet_module, catch_changes: true)
  end

  describe 'required services' do
    describe command('curl https://`hostname -f`/login --insecure --location --verbose') do
      its(:stdout) { should contain('Jenkins') }
    end
  end

end
