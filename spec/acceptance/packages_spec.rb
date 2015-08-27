require 'spec_helper_acceptance'

describe 'packages' do
  describe 'operating system packages' do
    describe 'operating system packages installed on jenkins master' do
      required_packages = [
        package('jenkins'),
        package('openjdk-7-jre-headless'),
        package('python-babel'),
        package('python-jenkins'),
        package('python-sqlalchemy'),
        package('python-yaml'),
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
    end

    describe 'operating system packages installed on jenkins slave' do
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

  describe 'pip packages' do
    describe 'pip packages installed on jenkins slave' do
      packages = [
        package('git-review'),
        package('tox'),
      ]

      packages.each do |package|
        describe package do
          it { should be_installed.by('pip') }
        end
      end
    end
  end
end
