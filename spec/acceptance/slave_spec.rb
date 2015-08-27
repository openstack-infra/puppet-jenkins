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

  def jenkins_slave_puppet_module
    module_path = File.join(pp_path, 'slave.pp')
    File.read(module_path)
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

  describe 'required files' do
    describe file('/home/jenkins/.gitconfig') do
      it { should be_file }
      its(:content) { should match '[user]' }
      its(:content) { should match 'name = OpenStack Jenkins' }
      its(:content) { should match 'email = jenkins@openstack.org' }
      its(:content) { should match '[gitreview]' }
      its(:content) { should match 'username = jenkins' }
    end

    describe file('/home/jenkins/.m2/settings.xml') do
      it { should be_file }
      its(:content) { should match '<id>jenkins</id>' }
      its(:content) { should match '<url>http://repo.jenkins-ci.org/public/</url>' }
    end

    describe file('/home/jenkins/.ssh/config') do
      it { should be_file }
      its(:content) { should match 'StrictHostKeyChecking=no' }
    end

    jenkins_user_directories = [
      file('/home/jenkins/.pip'),
      file('/home/jenkins/.config'),
    ]

    jenkins_user_directories.each do |directory|
      describe directory do
        it { should be_directory }
        it { should be_owned_by 'jenkins' }
        it { should be_grouped_into 'jenkins' }
      end
    end

    jenkins_user_files = [
      file('/home/jenkins/.bash_logout'),
      file('/home/jenkins/.bashrc'),
      file('/home/jenkins/.gnupg/pubring.gpg'),
      file('/home/jenkins/.profile'),
      file('/home/jenkins/.ssh/authorized_keys'),
    ]

    jenkins_user_files.each do |file|
      describe file do
        it { should be_file }
      end
    end

    describe 'symlinkies' do
      symlinkies = {
        file('/usr/local/bin/c++') => '/usr/bin/ccache',
        file('/usr/local/bin/cc')  => '/usr/bin/ccache',
        file('/usr/local/bin/g++') => '/usr/bin/ccache',
        file('/usr/local/bin/gcc') => '/usr/bin/ccache',
      }

      symlinkies.each do |link, destination|
        describe link do
          it { should be_symlink }
          it { should be_linked_to destination }
        end
      end
    end

    describe file('/usr/local/jenkins') do
      it { should be_directory }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end
  end

  describe 'required packages' do
    if ['ubuntu', 'debian'].include?(os[:family]) then
      required_packages = [
        package('build-essential'),
        package('ccache'),
        package('maven2'),
        package('openjdk-7-jdk'),
        package('python-netaddr'),
        package('ruby1.9.1'),
      ]
    elsif ['centos', 'redhat'].include?(os[:family]) then
      required_packages = [
        package('ccache'),
        package('java-1.7.0-openjdk-devel'),
        package('python-netaddr'),
      ]
    end

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

    pip_packages = [
      package('git-review'),
      package('tox'),
    ]

    pip_packages.each do |package|
      describe package do
        it { should be_installed.by('pip') }
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

describe 'puppet-jenkins jenkins-job-builder module', :if => ['debian', 'ubuntu'].include?(os[:family]) do
  describe 'required files' do
    describe file('/etc/jenkins_jobs/jenkins_jobs.ini') do
      its(:content) { should match '[jenkins]' }
      its(:content) { should match 'user=jenkins' }
      its(:content) { should match 'password=secret' }
      its(:content) { should match 'url=https://127.0.0.1' }
    end

    describe file('/etc/jenkins_jobs/config') do
      it { should be_directory }
      it { should be_owned_by 'root' }
      it { should be_grouped_into 'root' }
    end
  end

  describe 'required packages' do
    describe package('python-jenkins') do
      it { should be_installed.by('pip') }
    end

    describe package('python-yaml') do
      it { should be_installed }
    end
  end
end
