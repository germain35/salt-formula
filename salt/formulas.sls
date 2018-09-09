{% set processed_formuladirs = [] %}
{% set processed_basedirs = [] %}

{% from "salt/formulas.jinja" import formulas_opt with context %}

# Loop over all formulas listed in pillar data
{% for env, entries in salt['pillar.get']('salt_formulas:list', {}).items() %}
{% for entry in entries %}

{% set basedir = formulas_opt(env, 'basedir')|load_yaml %}
{% set formuladir = '{0}/{1}'.format(basedir, entry.name) %}
{% set update = formulas_opt(env, 'update')|load_yaml %}

# Setup the directory hosting the repository
{% if basedir not in processed_basedirs %}
{% do processed_basedirs.append(basedir) %}
{{ basedir }}:
  file.directory:
    {%- for key, value in salt['pillar.get']('salt_formulas:basedir_opts',
                                             {'makedirs': True}).items() %}
    - {{ key }}: {{ value }}
    {%- endfor %}
{% endif %}

# Setup the formula repository
{% if formuladir not in processed_formuladirs %}
{% do processed_formuladirs.append(formuladir) %}
{% set options = formulas_opt(env, 'options')|load_yaml %}
{% set baseurl = formulas_opt(env, 'baseurl')|load_yaml %}
{% if entry.source is defined %}
{{ formuladir }}:
  archive.extracted:
    - source: {{ entry.source }}
    {%- if entry.source_hash is defined %}
    - source_hash: {{ entry.source_hash }}
    {%- else %}
    - skip_verify: True
    {%- endif %}
    - enforce_toplevel: False
    - options: --strip-components=1
    - user: {{ salt['pillar.get']('salt_formulas:basedir_opts:user', 'root') }}
    - group: {{ salt['pillar.get']('salt_formulas:basedir_opts:group', 'root') }}
    - force: True
    - overwrite: True
    - trim_output: True
{% else %}
{{ formuladir }}:
  git.latest:
    - name: {{ baseurl }}/{{ entry }}.git
    - target: {{ formuladir }}
    {%- for key, value in options.items() %}
    - {{ key }}: {{ value }}
    {%- endfor %}
    - require:
      - file: {{ basedir }}
    {%- if not update %}
    - unless: test -e {{ formuladir }}
    {%- endif %}
{% endif %}
{% endif %}

{% endfor %}
{% endfor %}
