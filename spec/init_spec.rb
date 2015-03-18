# for serverspec documentation: http://serverspec.org/
require_relative 'spec_helper'

packages = ['python-dev','python-pip']

packages.each do | package |
  describe package("#{package}") do
    it{ should be_installed }
  end
end

pip_packages = ['whisper']

pip_packages.each do | pip_package |
  describe package("#{pip_package}") do
    it { should be_installed.by('pip') }
  end
end

describe file("/data/graphite/conf/carbon.conf") do
  it{ should be_file }
  it{ should be_owned_by 'root' }
  it{ should be_grouped_into 'root' }
  it{ should be_mode 644}
  its(:content) { should match /DESTINATIONS = 10.0.2.15:2103:1/ }
  its(:content) { should match /DESTINATIONS = 127.0.0.1:2003:1, 127.0.0.1:2004:2/ }
  its(:content) { should match /PICKLE_RECEIVER_INTERFACE = 127.0.0.1/ }
end

describe file("/data/graphite/conf/storage-schemas.conf") do
  it{ should be_file }
  it{ should be_owned_by 'root' }
  it{ should be_grouped_into 'root' }
  it{ should be_mode 644}
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

describe file("/etc/init.d/carbon-relay-2") do
  it{ should be_file }
  it{ should be_owned_by 'root' }
  it{ should be_grouped_into 'root' }
  it{ should be_mode 755}
  path = File.expand_path("../test_files/carbon-relay-2", __FILE__)
  its(:content) { should eq IO.read(path) }
end

services=['carbon-cache-1','carbon-cache-2','carbon-relay-1','carbon-relay-2']

services.each do | service |
  describe service("#{service}") do
    it { should be_enabled }
    it { should be_running }
  end
end
