{% from "graphite/settings.sls" import graphite with context %}

include:
  - graphite

graphite-web:
  pip.installed:
    - name: graphite-web == {{ graphite.web_version }}
    - install_options:
      - --prefix=/data/graphite
      - --install-lib=/data/graphite/webapp
    - require:
      - pkg: python-pip

graphite-web.egg-info.symlink:
    file.symlink:
        - name: /usr/lib/python2.7/dist-packages/graphite_web-{{ graphite.carbon_version }}-py2.7.egg-info
        - target: {{ graphite.install_path }}/webapp/graphite_web-{{ graphite.web_version }}-py2.7.egg-info
        - force: true

{{ graphite.install_path }}/webapp/graphite/local_settings.py:
  file.managed:
    - source: salt://graphite/templates/web/local_settings.py
    - template: jinja
    - require:
      - pip: graphite-web
