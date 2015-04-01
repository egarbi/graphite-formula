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
