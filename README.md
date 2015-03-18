template-formula
================

A SaltStack formula that dynamically sets up a graphite server with the number of relays or caches you desire. 

States
======

``graphite``
------------

Provisions the system with graphite caches and relays defined in the grains of the server.

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

Defines the defaults for the settings for graphite caches and relays. Currently the defaults are laid out as follows. 

```
default_cache:
  enable_logrotation: True
  enable_udp_listener: False
  user:
  max_cache_size: inf
  max_updates_per_second: 500
  max_creates_per_minute: 50
  log_listener_connections: True
  use_insecure_unpickler: False
  use_flow_control: True
  log_updates: False
  log_cache_hits: False
  log_cache_queue_sorts: True
  cache_write_strategy: sorted
  whisper_autoflush: False
  whisper_fallocate_create: True

default_relay
  log_listener_connections: True
  replication: 1
  relay_method: consistent-hashing
  destinations:
    - 127.0.0.1:2003:1
  max_datapoints_per_message: 500
  max_queue_size: 10000
  queue_low_watermark_pct: 0.8
  use_flow_control: True
```

These defaults were taken from the carbon.conf.example that is laid down with the package installation. When you define your own relay or cache any setting you choose not to define will be automatically populated with the default above. You can override any of these settings in your relay or cache by defining the value you desire in your grains. Please go to the graphite documentation link [HERE](http://graphite.readthedocs.org/en/latest/config-carbon.html#storage-schemas-conf) to learn more about these settings. 

## Defining a cache

A cache will be defined and laid out in your server grains. For example the following will define a private cache.

```
graphite:
  config:
    caches:
      - public: false
```

Private meaning that the cache will bind to `127.0.0.1` so it will only be accessible to localhost. If `public: true` then the cache will bind to `0.0.0.0`.

To override default settings for a cache you can do the following. 
```
graphite:
  config:
    caches:
      - public: false
        max_updates_per_second: 1500
      - public: false
        max_updates_per_second: 1500
```

This will create a system with two carbon caches and will override the default `max_updates_per_second` of 500 and set it to 1500. 

####Ports

The cache ports are located at `200*`. The line port is the cache number. So cache #1 above would have a line port of `2001`, cache #2 would have a line port of `2002`. 

The pickle port is located at the `cache # + total # of caches`. So `cache #1` pickle port is located at `2003` and `cache #2` pickle port is located at `2004`


## Defining a relay

A relay will be defined and laid out in your server grains. For example the following will define a private relay.

```
graphite:
  config:
    relays:
      - public: true
        replication: 2
        destinations:
          - 127.0.0.1:2003:1
          - 127.0.0.1:2004:2
```

A relay has to have destinations. So in this example we are connecting to the pickle ports of the caches we defined in the last example. We know that their pickle ports are at `2003` and `2004`. We have also overridden the default replication value of 1 to ensure we duplicate stats to the two caches. This is not a practical real world configuration, but demonstrates the ability to create many different relay setups. 

#### Relay Clusters

To get graphite into a high availability setup you may need to setup relays that are cluster aware. This formula allows you to do so. It is assumed that the first relay defined on a server will be public facing. It is also assumed that all graphite nodes in a cluster have the same number of relays, this is how we dynamically figure out the correct pickle port to connect to. **Currently we do not support a cluster where the cluster relay connects directly to a carbon cache. **

***Example:***

```
roles:
  - graphite 
  
graphite:
  cluster_name: test_cluster
  config:
    relays:
      - public: true
        destinations:
          - 127.0.0.1:2003:1
          - 127.0.0.1:2004:2
      - public: true
        replication: 2
        destinations: mine_relays
```

The result of this configuration is that salt will find all the nodes that have the grain `graphite:cluster_name` set to `test_cluster`. It will harvest those ips and dynamically create the config for `relay #2` to connect to `relay #1` on each of those hosts in the cluster. So if there are three nodes in the cluster at the following ip addresses `['10.0.2.15', '10.0.2.16', '10.0.2.17']`, then the following would be written to the `carbon.conf` file. 

```
DESTINATIONS = 10.0.2.15:2103:1, 10.0.2.16:2103:1, 10.0.2.17:2103:1
```

It is worth noting that the grain `roles:graphite` must be defined for a node for the `mine_relays` function to work properly. 

####Ports

The relays ports are located at `210*`. The line port is the relay number. So relay #1 above would have a line port of `2101`, relay #2 would have a line port of `2102`. 

The pickle port is located at the `relay # + total # of relays`. So `relay #1` pickle port is located at `2103` and `relay #2` pickle port is located at `2104`

## Storage Schemas

Storage schemas determine how long stats are kept on the graphite instance. If no storage schema is defined in the grains data the default is the following. 

```
# Schema definitions for Whisper files. Entries are scanned in order,
# and first match wins. This file is scanned for changes every 60 seconds.
#
#  [name]
#  pattern = regex
#  retentions = timePerPoint:timeToStore, timePerPoint:timeToStore, ...

# Carbon's internal metrics. This entry should match what is specified in
# CARBON_METRIC_PREFIX and CARBON_METRIC_INTERVAL settings
[carbon]
pattern = ^carbon\.
retentions = 60:90d

[default_1min_for_1day]
pattern = .*
retentions = 60s:1d
```

To define a storage schema you must provide it in the grain data. Please see the example below. 


    roles:
      - graphite

    graphite:
        storage_schemas: |
          [carbon]
          pattern = ^carbon\.
          retentions = 60:90d
          
          [default_1min_for_1day]
          pattern = .*
          retentions = 60s:1d

 
 To read more about storage schemas for graphite please read the docs [HERE](http://graphite.readthedocs.org/en/latest/config-carbon.html#storage-schemas-conf).
 



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
