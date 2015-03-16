{% set p    = salt['pillar.get']('graphite', {}) %}
{% set pc   = p.get('config', {}) %}
{% set g    = salt['grains.get']('graphite', {}) %}
{% set gc   = g.get('config', {}) %}

{%- set default_cache = {} %}
{%- set default_relay = {} %}

{%- do default_cache.update({
  'enable_logrotation'       : True,
  'enable_udp_listener'      : False,
  'user'                     : '',
  'max_cache_size'           : 'inf',
  'max_updates_per_second'   : '500',
  'max_creates_per_minute'   : '50',
  'log_listener_connections' : True,
  'use_insecure_unpickler'   : False,
  'use_flow_control'         : True,
  'log_updates'              : False,
  'log_cache_hits'           : False,
  'log_cache_queue_sorts'    : True,
  'cache_write_strategy'     : 'sorted',
  'whisper_autoflush'        : False,
  'whisper_fallocate_create' : True
}) %}

{%- do default_relay.update({
  'log_listener_connections' : True,
  'relay_method' : 'consistent-hashing',
  'replication_factor' : 1,
  'destinations' : [ '127.0.0.1:2001:1' ],
  'max_datapoints_per_message' : 500,
  'max_queue_size' : 10000,
  'queue_low_watermark_pct' : '0.8',
  'use_flow_control' : True
}) %}

{%- set graphite = {} %}
{%- do graphite.update( {
  'caches' : gc.get('caches', default_cache),
  'relays' : gc.get('relays', default_relay)
}) %}
