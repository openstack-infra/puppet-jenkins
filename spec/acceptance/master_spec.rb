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
    describe command('curl http://127.0.0.1 --verbose') do
      its(:stdout) { should contain('302 Found') }
      its(:stdout) { should contain('The document has moved') }
    end

    describe command('curl http://127.0.0.1 --insecure --location --verbose') do
      its(:stdout) { should contain('Jenkins') }
    end

    describe command('curl https://127.0.0.1 --insecure') do
      its(:stdout) { should contain('Jenkins') }
    end

    describe command('curl 127.0.0.1:8080') do
      its(:stdout) { should contain('Jenkins') }
    end
  end

end
