# for serverspec documentation: http://serverspec.org/
require_relative 'spec_helper'

packages = %w[
  libapache2-mod-wsgi
  memcached
  python-cairo-dev
  python-django
  python-django-tagging
  python-memcache
  python-rrdtool
  ]

packages.each do | package |
  describe package("#{package}") do
    it{ should be_installed }
  end
end

pip_packages = %w[
  graphite-web
  ]

pip_packages.each do | pip_package |
  describe package("#{pip_package}") do
    it { should be_installed.by('pip').with_version('0.9.13') }
  end
end

describe file("/data/graphite/storage/log/webapp") do
  it{ should be_directory }
  it{ should be_owned_by 'www-data' }
  it{ should be_grouped_into 'www-data' }
end

describe file("/data/graphite/conf/graphTemplates.conf") do
  it{ should be_file }
  it{ should be_mode 755}
end

describe file("/data/graphite/webapp/graphite/local_settings.py") do
  it{ should be_file }
  #TODO Check content
end

describe file("/data/graphite/conf/graphite.wsgi") do
  it{ should be_file }
  #TODO Check content
end

describe file("/data/graphite/storage/graphite.db") do
  it{ should be_file}
end

describe file("/etc/apache2/sites-enabled/graphite-web.conf") do
  it{ should be_file}
  #TODO check contents
end

describe port(80) do
  it { should be_listening }
end
