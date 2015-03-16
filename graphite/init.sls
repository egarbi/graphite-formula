{% from "graphite/settings.sls" import graphite with context %}

python-dev:
  pkg.installed

python-pip:
  pkg.installed

cache_config:
  file.managed:
    - name: /data/graphite/conf/carbon.conf
    - source: salt://graphite/templates/carbon.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        caches: {{ graphite.caches }}
        relays: {{ graphite.relays }}

carbon:
  pip.installed:
    - install_options:
      - --prefix=/data/graphite
      - --install-lib=/data/graphite/lib
    - require:
      - pkg: python-pip

whisper:
  pip.installed:
    - require:
      - pkg: python-pip

https://github.com/graphite-project/ceres/tarball/master:
  pip.installed:
    - require:
      - pkg: python-pip
