{% from "salt/map.jinja" import salt_settings with context %}

include:
  - salt.master

{%- if 'rest_cherrypy' in salt['pillar.get']('salt:master', {}) %}
  {%- if salt_settings.install_packages %}
    {%- if salt_settings.python_cherrypy.install_from_pip %}
salt-api_python_packages:
  pkg.installed:
    - pkgs: 
      - python-pip
      - python-setuptools
    - reload_modules: true

salt-api_cherrypy_package:
  pip.installed:
    - name: {{ salt_settings.python_cherrypy.pip_pkg }}
    {%- if salt_settings.python.pip.get('no_index', False) %}
    - no_index: True
    {%- endif %}
    {%- if salt_settings.python.pip.get('index_url', False) %}
    - index_url: {{ salt_settings.python.pip.index_url }}
      {%- if salt_settings.python.pip.get('trusted_host', False) %}
    - trusted_host: {{ salt_settings.python.pip.trusted_host }}
      {%- endif %}
    {%- endif %}
    {%- if salt_settings.python.pip.get('find_links', False) %}
    - find_links: {{ salt_settings.python.pip.find_links }}
    {%- endif %}
    - require:
      - pkg: salt-api_python_packages
    - require_in:
      - pkg: salt-api
    {%- else %}
salt-api_cherrypy_package:
  pkg.installed:
    - name: {{ salt_settings.python_cherrypy.pkg }}
    - require_in:
      - pkg: salt-api
    {%- endif %}
  {%- endif %}
{%- endif %}

salt-api:
{% if salt_settings.install_packages %}
  pkg.installed:
    - name: {{ salt_settings.salt_api }}
  {%- if salt_settings.version is defined %}
    - version: {{ salt_settings.version }}
  {%- endif %}
{% endif %}
  service.running:
    - enable: True
    - name: {{ salt_settings.api_service }}
    - require:
      - service: {{ salt_settings.master_service }}
    - watch:
{% if salt_settings.install_packages %}
      - pkg: salt-api
{% endif %}
      - file: salt-master
