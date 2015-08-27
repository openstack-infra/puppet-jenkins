require 'spec_helper_acceptance'

describe 'files and directories' do
  describe 'jenkins user files and directories' do
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
  end

  describe 'jenkins master files and directories' do
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

      describe file('/etc/jenkins_jobs/jenkins_jobs.ini') do
        its(:content) { should match '[jenkins]' }
        its(:content) { should match 'user=jenkins' }
        its(:content) { should match 'password=secret' }
        its(:content) { should match 'url=https://localhost' }
      end

      describe file('/etc/jenkins_jobs/config') do
        it { should be_directory }
        it { should be_owned_by 'root' }
        it { should be_grouped_into 'root' }
      end
    end
  end

  describe 'jenkins slave files and directories' do
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
end
