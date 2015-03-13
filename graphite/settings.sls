{% set p    = salt['pillar.get']('graphite', {}) %}
{% set pc   = p.get('config', {}) %}
{% set g    = salt['grains.get']('graphite', {}) %}
{% set gc   = g.get('config', {}) %}

{%- set graphite = {} %}
{%- do graphite.update( {
  'relays'           : gc.get('relays', []),
  'caches'       : gc.get('caches', [])
}) %}
