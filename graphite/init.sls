{% from "graphite/settings.sls" import graphite with context %}

python-dev:
  pkg.installed

python-pip:
  pkg.installed

/data/graphite/conf/carbon.conf:
  file.managed:
    - source: salt://graphite/templates/carbon.conf
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        relays: {{ graphite.relays }}
        caches: {{ graphite.caches }}

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

graphite-web:
  pip.installed:
    - require:
      - pkg: python-pip

https://github.com/graphite-project/ceres/tarball/master:
  pip.installed:
    - require:
      - pkg: python-pip
