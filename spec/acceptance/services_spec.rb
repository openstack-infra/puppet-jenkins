require 'spec_helper_acceptance'

describe 'services' do
  describe 'jenkins is available' do
    describe command('curl http://localhost --verbose') do
      its(:stdout) { should contain('302 Found') }
      its(:stdout) { should contain('The document has moved') }
    end

    describe command('curl http://localhost --insecure --location --verbose') do
      its(:stdout) { should contain('Jenkins') }
    end

    describe command('curl https://localhost --insecure') do
      its(:stdout) { should contain('Jenkins') }
    end

    describe command('curl localhost:8080') do
      its(:stdout) { should contain('Jenkins') }
    end
  end
end
