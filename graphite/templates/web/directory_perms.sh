{%- from "graphite/settings.sls" import graphite with context %}
#/bin/bash
f={{ graphite.install_path }}
while [[ $f != "/" ]]; do chmod 755 $f; f=$(dirname $f); done;
touch {{ graphite.install_path }}/perms_set
