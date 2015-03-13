#!/usr/bin/env ruby

require 'yaml'

path = File.expand_path('../', File.dirname(__FILE__))

base = File.basename(path)
name = base.partition('-').first

# create the main formula symlink
unless name.to_s == ''
  `ln -sfn /vagrant/#{name} #{name}`
end

# grab all our listed dependencies
if File.exist?('./deps.yml')

  # create a deps dir
  `mkdir -p ./deps`

  deps = begin
    YAML.load_file('./deps.yml')
  rescue ArgumentError => e
    puts "Could not parse YAML: #{e.message}"
    exit 1
  end

  unless deps['repositories'].to_s == ''
    deps['repositories'].each { |name, remote|

      # if repo exists, attempt silent clone;
      # otherwise, attempt silent update

      unless File.exist?("./deps/#{name}-formula")

        `git clone -q #{remote} ./deps/#{name}-formula`

      else

        Dir.chdir("./deps/#{name}-formula") do
          `git checkout -q master`
          `git pull -q origin master`
        end

      end

      # create base formula dir symlink for this formula dependency
      `ln -sfn ./deps/#{name}-formula/#{name} #{name}`
    }
  end

else
  puts 'Could not find ./deps.yml file!, exiting...'
  exit 1
end

exit 0
