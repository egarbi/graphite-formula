template-formula
================

A SaltStack formula that attempts to capture our team's formula design patterns.

States
======

``template``
------------

Provisions the system with the template init.sls state file.

Formula structure
=================

## Directory layout:

    ├── ./LICENSE
    ├── ./README.md
    ├── ./Vagrantfile
    ├── ./spec
    │   ├── ./spec/init_spec.rb
    │   └── ./spec/spec_helper.rb
    └── ./template
        ├── ./template/files
        ├── ./template/init.sls
        ├── ./template/settings.sls
        └── ./template/templates

* README.md - a README to describe the Salt formula.
* LICENSE - a LICENSE file.
* Vagrantfile - a Vagrant server file
* spec/ - the RSpec testing directory.
* template/ - the main Salt formula directory and the collection of Salt state files.
* template/files/ - a directory for non-Jinja template files used in the formula.
* template/templates/ - a directory for Jinja template files used in the formula.

## settings.sls:

We use a special file called 'settings.sls' to define global values for our Salt formulas.

We specifically have our settings.sls files setup to leverage grains, the Pillar, and then a local
default value. This means that for certain global values we can look for the value in either
the minion's list of grains, on the Salt master's Pillar or locally from the settings.sls file.

####Pillars might be, but are not limited to: 

* Things we want to keep globally constant 
	* package versions
	* install locations
* For secrets and passwords 
	* service api keys
	* root passwords for services like mysql 

####Grains might be, but are not limited to: 

* Machine specific configuration 
	* JVM heapspace 
	* Mysql logfile size  
* For coordination of clusters
	* Which cluster a machine is part of 
	* How data should be sharded in a cluster   
* Metadata
	* Things we want to be able to query in our infrastructure 
		
####When to use a grain or a pillar 
Since pillars and grains serve different purposes it is important to take some time to consider when to use one or the other. The situations above are a good starting guide, but a general rule of thumb can be established by asking yourself, "Is this thing global and something I want for all my infrastructure?" If the answer is yes, then its a pillar if the answer is no, then the thing is a grain. 

####Should grains override pillars? 
Only in very special cases should grains override pillars. The two objects have fundamentally different purposes, so we should be diligent to ensure we try to keep to those purposes. If a grain is allowed to override a pillar we break the contract that pillar data keeps our infrastructure consistent. When that contract is broken we then open up the possibility for snowflake infrastructure that can make it harder to troubleshoot issues. 

####Settings.sls example
The following is an example of a 'settings.sls' file and shows how we use grains, Pillar, and local
settings.sls values for formula globals:

    {% set p    = salt['pillar.get']('template', {}) %}
    {% set pc   = p.get('config', {}) %}
    {% set g    = salt['grains.get']('template', {}) %}
    {% set gc   = g.get('config', {}) %}

    {%- set template = {} %}
    {%- do template.update( {
      'pkg'           : pc.get('pkg', 'apache2'),
      'service'       : pc.get('service', 'apache2'),
      'config_file'   : gc.get('config_file', pc.get('config_file', '/etc/apache2/apache2.conf')),
      }) %}

One thing to note about the above example is that we explicitly call out the configurations we need. The settings.sls should be verbose and best practice is to limit your configuration values to a single value for a single key. There may be special situations where lists and dictionaries are appropriate, but in general the rule of thumb is to keep to a single value for each key in the settings.sls. 

In the above example for the key `pkg` we have `pc.get('pkg','apache2')`, the `get` function is a python dictionary function. The first argument for `get` is the key your are trying to receive from the dictionary, in this case we are looking for the ket `pkg`. The second argument of `get` is a default value to return if the key is not found. So in this settings.sls if the key `pkg` does not exist in `pillar['template']['config']` then we return `apache`. 

Defaults should be defined in all cases where you don't want to force the user to set a value. There may be some very special cases where a good default is impossible to predict and in those cases a user should be forced to define the value. 

####Importing settings.sls from dependent projects

There may be some cases where a pillar and grain data that is defined for one formula may be required by another. In these cases it is best to access the `settings.sls` file directly from that depended formula. For example if I needed the mysql root password to define some users I would add the following to the top of the state file that needed access to the mysql pillar and grain data. 

```
{% from "salt://mysql/settings.sls" import mysql with context %}
```

The important thing to note in the above line is `salt://`. This tells the salt minion to access the salt file server to retrieve the `mysql/settings.sls` file. This is a powerful tool because it allows us to test effectively in our vagrant environments, while also being confident that this statement will work equally as well in production environments. 


Vagrant testing
===============

## Vagrantfile & .vagrant-salt/:

This repo includes a Vagrantfile which is to be used for formula testing and
it illustrates how we leverage Vagrant to test all of our SaltStack formulas.

In the Vagrantfile you will notice that when the Vagrant VM is initialized, this
formula's directory will become the /vagrant partition on the VM. You will also
notice that the .vagrant-salt/ directory in this repo will become the /srv/salt
directory on the VM - the main SaltStack formula tree directory.

In the .vagrant-salt/ directory there are a few files that help with local
Vagrant testing. These files are:

* deps.rb - a Ruby tool to handle Salt formula dependency management.
* deps.yml - a YAML file which is used by deps.rb to determine the formula dependencies.
* grains - a YAML Salt grains file for setting up the VM with grains for testing.
* minion - a Salt minion configuration file to set up the minion's settings.
* top.sls - a base Salt top.sls file for describing which formulas to apply on the test VM.

## deps.rb & deps.yml:

The deps.rb script is a helper script found under .vagrant-salt/ and automatically downloads
any Salt formula dependencies required by the formula based on which git repositories are
listed in the deps.yml file. A Salt formula developer should only have to update the deps.yml
file in order to obtain any Salt formulas that their current formula requires.

The deps.rb script creates pertinent symlinks in .vagrant-salt/ to enable proper Vagrant VM testing.

## serverspec:

This repo includes a spec/ directory with RSpec test files. The convention we use for naming
our spec test files is to prefix the filename with the respective Salt state file name.

E.g. the spec test file 'init_spec.rb' is a spec test file for the 'init.sls' file.

The Salt formula developer should add tests to the spec/ directory to ensure that the
Salt formula is properly tested and maintainable.

## Testing execution:

To test your Salt formula by bringing up a Vagrant VM, provisioning with Salt, and running
the serverspec tests, perform either of the following depending on your needs:

    $: vagrant up
    $: vagrant provision
    $: vagrant provision --provision-with salt
    $: vagrant provision --provision-with serverspec
