{% from "graphite/settings.sls" import graphite with context %}

include:
  - graphite

salt://graphite/templates/web/directory_perms.sh:
    cmd.script:
      - template: jinja
      - creates: {{ graphite.install_path }}/perms_set

{{ graphite.install_path }}/conf:
  file.directory:
    - mode: 755
    - recurse:
      - mode

dependent_packages:
  pkg.installed:
    - names:
      - libapache2-mod-wsgi
      - memcached
      - python-cairo-dev
      - python-django
      - python-django-tagging
      - python-memcache
      - python-rrdtool
    - require:
      - pkg: apache2
    - require_in:
      - cmd: init_db
    - require_in:
      - file: /etc/apache2/sites-enabled/graphite-web.conf

graphite-web:
  pip.installed:
    - name: graphite-web == {{ graphite.web_version }}
    - install_options:
      - --prefix={{ graphite.install_path }}
      - --install-lib={{ graphite.install_path }}/webapp
    - require:
      - pkg: python-pip

graphite-web.egg-info.symlink:
    file.symlink:
        - name: /usr/lib/python2.7/dist-packages/graphite_web-{{ graphite.carbon_version }}-py2.7.egg-info
        - target: {{ graphite.install_path }}/webapp/graphite_web-{{ graphite.web_version }}-py2.7.egg-info
        - force: true
        - require:
          - pip: graphite-web

{{ graphite.install_path }}/storage/log/webapp:
  file.directory:
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - group

{{ graphite.install_path }}/conf/graphTemplates.conf:
  file.managed:
    - mode: 755
    - source: salt://graphite/files/graphTemplates.conf

{{ graphite.install_path }}/webapp/graphite/local_settings.py:
  file.managed:
    - source: salt://graphite/templates/web/local_settings.py
    - template: jinja
    - require:
      - pip: graphite-web

{{ graphite.install_path }}/conf/graphite.wsgi:
  file.managed:
    - source: salt://graphite/templates/web/graphite.wsgi
    - template: jinja
    - require:
      - pip: graphite-web

{% for mod in ['wsgi','socache_shmcb', 'rewrite'] %}
{{ mod }}:
  apache_module.enable:
    - require:
      - pkg: apache2
      - pkg: libapache2-mod-wsgi
    - require_in:
      - file: /etc/apache2/sites-enabled/graphite-web.conf
{% endfor %}

init_db:
  cmd.run:
    - name: python manage.py syncdb --noinput
    - cwd: {{ graphite.install_path }}/webapp/graphite/
    - creates: {{ graphite.install_path }}/storage/graphite.db
    - require:
      - pip: graphite-web

{{ graphite.install_path }}/storage/graphite.db:
  file.managed:
    - user: www-data
    - group: www-data
    - mode: 755
    - require:
      - cmd: init_db
    - require_in:
      - file: /etc/apache2/sites-enabled/graphite-web.conf

/etc/apache2/sites-enabled/graphite-web.conf:
  file.managed:
    - source: salt://graphite/templates/web/vhost.conf
    - template: jinja
    - require:
      - apache_module: wsgi
      - file: /etc/apache2/sites-enabled/000-default.conf
      - file: {{ graphite.install_path }}/conf/graphite.wsgi
      - file: {{ graphite.install_path }}/webapp/graphite/local_settings.py
      - file: {{ graphite.install_path }}/conf/graphTemplates.conf
      - file: {{ graphite.install_path }}/storage/log/webapp
      - file: {{ graphite.install_path }}/conf
      - pip: graphite-web
      - cmd: salt://graphite/templates/web/directory_perms.sh
    - watch_in:
      - service: apache2
