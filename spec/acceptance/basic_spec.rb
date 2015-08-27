require 'spec_helper_acceptance'

describe 'puppet-jenkins module' do
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

  def jenkins_slave_puppet_module
    module_path = File.join(pp_path, 'slave.pp')
    File.read(module_path)
  end

  before(:all) do
    apply_manifest(preconditions_puppet_module, catch_failures: true)
  end

  describe 'jenkins slave' do
    it 'should work with no errors' do
      apply_manifest(jenkins_slave_puppet_module, catch_failures: true)
    end

    it 'should be idempotent' do
      apply_manifest(jenkins_slave_puppet_module, catch_failures: true)
      apply_manifest(jenkins_slave_puppet_module, catch_changes: true)
    end
  end

  describe 'jenkins master' do
    it 'should work with no errors' do
      apply_manifest(jenkins_master_puppet_module, catch_failures: true)
    end

    it 'should be idempotent' do
      apply_manifest(jenkins_master_puppet_module, catch_failures: true)
      apply_manifest(jenkins_master_puppet_module, catch_changes: true)
    end
  end
end
