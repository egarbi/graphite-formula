# for serverspec documentation: http://serverspec.org/
require_relative 'spec_helper'

packages = %w[
  apache2
  libcairo2-dev
  libffi-dev
  python-dev
  python-pip
  ]

packages.each do | package |
  describe package("#{package}") do
    it{ should be_installed }
  end
end

pip_packages = %w[
  whisper
  carbon
  ]

pip_packages.each do | pip_package |
  describe package("#{pip_package}") do
    it { should be_installed.by('pip').with_version('0.9.13') }
  end
end

describe file("/etc/apache2/sites-enabled/000-default.conf") do
  it{ should_not be_file }
end

describe user('carbon') do
  it { should belong_to_group 'carbon' }
  it { should have_uid 4000 }
  it { should have_home_directory '/home/carbon'}
  it { should have_login_shell '/bin/bash' }
end

describe group('carbon') do
  it { should exist }
  it { should have_gid 4000 }
end

describe file("/data/graphite/conf/carbon.conf") do
  it{ should be_file }
  it{ should be_owned_by 'root' }
  it{ should be_grouped_into 'root' }
  it{ should be_mode 755}
  its(:content) { should match /DESTINATIONS = 10.0.2.15:2103:1/ }
  its(:content) { should match /DESTINATIONS = 127.0.0.1:2003:1, 127.0.0.1:2004:2/ }
  its(:content) { should match /PICKLE_RECEIVER_INTERFACE = 127.0.0.1/ }
end
describe file("/data/graphite/conf/storage-schemas.conf") do
  it{ should be_file }
  it{ should be_owned_by 'root' }
  it{ should be_grouped_into 'root' }
  it{ should be_mode 755}
end

describe file("/data/graphite/bin/carbon-relay.py") do
  it{ should be_file }
  it{ should be_owned_by 'root' }
  it{ should be_grouped_into 'root' }
  it{ should be_mode 755}
end

describe file("/data/graphite/bin/carbon-cache.py") do
  it{ should be_file }
  it{ should be_owned_by 'root' }
  it{ should be_grouped_into 'root' }
  it{ should be_mode 755}
end

describe file("/etc/init.d/carbon-cache-1") do
  it{ should be_file }
  it{ should be_owned_by 'root' }
  it{ should be_grouped_into 'root' }
  it{ should be_mode 755}
  path = File.expand_path("../test_files/carbon-cache-1", __FILE__)
  its(:content) { should eq IO.read(path) }
end

describe file('/data/graphite/storage') do
  it{ should be_directory }
end

describe file("/etc/init.d/carbon-relay-2") do
  it{ should be_file }
  it{ should be_owned_by 'root' }
  it{ should be_grouped_into 'root' }
  it{ should be_mode 755}
  path = File.expand_path("../test_files/carbon-relay-2", __FILE__)
  its(:content) { should eq IO.read(path) }
end

services= %w[
  carbon-cache-1
  carbon-cache-2
  carbon-relay-1
  carbon-relay-2
  apache2
  ]

services.each do | service |
  describe service("#{service}") do
    it { should be_enabled }
    it { should be_running }
  end
end
