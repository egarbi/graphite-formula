{% set p    = salt['pillar.get']('graphite', {}) %}
{% set pc   = p.get('config', {}) %}
{% set g    = salt['grains.get']('graphite', {}) %}
{% set gc   = g.get('config', {}) %}

{%- set default_cache = {} %}
{%- set default_relay = {} %}
{%- set force_mine_update = salt['mine.send']('network.ip_addrs') %}

{%- set cluster_name = salt['grains.get']('graphite:cluster_name') %}
{%- set graphite_host_dict = salt['mine.get']('G@roles:graphite and G@graphite:cluster_name:' + cluster_name + '', 'network.ip_addrs', 'compound') %}
{%- set graphite_ids = graphite_host_dict.keys() %}
{%- set graphite_hosts = graphite_host_dict.values() %}
{%- set destinations = [] %}
{%- for ip_addr in graphite_hosts %}
  {%- if 'relays' in gc %}
    {%- set num_of_relays = gc.get('relays',[])|length + 1 %}
    {{ destinations.append(ip_addr[0]+':210%s:1'|format(num_of_relays)) }}
  {%- endif %}
{%- endfor %}


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
  'replication': 1,
  'relay_method' : 'consistent-hashing',
  'destinations' : [ '127.0.0.1:2003:1' ],
  'max_datapoints_per_message' : 500,
  'max_queue_size' : 10000,
  'queue_low_watermark_pct' : '0.8',
  'use_flow_control' : True
}) %}


{%- for relay in gc.get('relays', []) %}
  {%- if relay.get('destinations','None') == 'mine_relays' %}
    {%- do relay.update({ 'destinations' : destinations}) %}
  {%- endif %}
{%- endfor %}


{%- set graphite = {} %}
{%- do graphite.update( {
  'caches' : gc.get('caches', [default_cache]),
  'relays' : gc.get('relays', [default_relay]),
  'carbon_version': pc.get('whisper_version', '0.9.13'),
  'install_path' : gc.get('install_path', '/data/graphite')
}) %}
