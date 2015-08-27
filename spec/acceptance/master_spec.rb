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

  describe 'required files' do
    describe 'jenkins master ssh keys' do
      describe file('/var/lib/jenkins/.ssh/id_rsa') do
        it { should be_file }
        its(:content) { should match '-----BEGIN RSA PRIVATE KEY-----' }
      end

      describe file('/var/lib/jenkins/.ssh/id_rsa.pub') do
        it { should be_file }
        its(:content) { should match 'ssh_rsa' }
      end
    end

    describe 'files and directories belonging to jenkins user and group' do
      files = [
        file('/var/lib/jenkins/.ssh/id_rsa'),
        file('/var/lib/jenkins/.ssh/id_rsa.pub'),
        file('/var/lib/jenkins/logger.conf'),
        file('/var/lib/jenkins/plugins/simple-theme-plugin/openstack-page-bkg.jpg'),
        file('/var/lib/jenkins/plugins/simple-theme-plugin/openstack.css'),
        file('/var/lib/jenkins/plugins/simple-theme-plugin/openstack.js'),
      ]

      files.each do |file|
        describe file do
          it { should be_file }
          it { should be_owned_by 'jenkins' }
          it { should be_grouped_into 'jenkins' }
        end
      end

      directories = [
        file('/var/lib/jenkins/.ssh'),
        file('/var/lib/jenkins/plugins'),
        file('/var/lib/jenkins/plugins/simple-theme-plugin'),
      ]

      directories.each do |directory|
        describe directory do
          it { should be_directory }
          it { should be_owned_by 'jenkins' }
          it { should be_grouped_into 'jenkins' }
        end
      end

    end
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

  describe 'required packages' do
    required_packages = [
      package('jenkins'),
      package('openjdk-7-jre-headless'),
      package('python-babel'),
      package('python-sqlalchemy'),
      package('sqlite3'),
      package('ssl-cert'),
    ]

    required_packages << package('apache2') if ['ubuntu', 'debian'].include?(os[:family])
    required_packages << package('httpd') if ['centos', 'redhat'].include?(os[:family])

    required_packages.each do |package|
      describe package do
        it { should be_installed }
      end
    end

    unnecessary_packages = [
      package('openjdk-6-jre-headless')
    ]

    unnecessary_packages.each do |package|
      describe package do
        it { should_not be_installed }
      end
    end
  end

  describe 'required users and groups' do
    describe group('jenkins') do
      it { should exist }
    end

    describe user('jenkins') do
      it { should exist }
      it { should belong_to_group 'jenkins' }
      it { should have_home_directory '/home/jenkins' }
      it { should have_login_shell '/bin/bash' }
    end
  end
end
