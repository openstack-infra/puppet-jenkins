require 'spec_helper_acceptance'

describe 'users and groups' do
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
