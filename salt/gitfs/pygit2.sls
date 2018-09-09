{% from "salt/map.jinja" import salt_settings with context %}
{% set pygit2_settings = salt_settings.gitfs.pygit2 %}

{% if pygit2_settings.git.get('require_state', False) %}
include:
  - {{ pygit2_settings.git.require_state }}
{% elif pygit2_settings.git.get('install_from_package', 'git') %}
pygit2-git:
  pkg.installed:
    - name: {{ pygit2_settings.git.install_from_package }}
{% endif %}

{% if pygit2_settings.install_from_source %}

  {% set libssh2_settings = pygit2_settings.libssh2 %}
  {% set libgit2_settings = pygit2_settings.libgit2 %}

  {% if libgit2_settings.install_from_source %}

# we probably don't have a package or it's not a high enough version
# install latest from source/pip
pygit2-deps:
  pkg.installed:
    - pkgs: {{ pygit2_settings.dep_pkgs }}

    {% set libgit2_src_dir   = libgit2_settings.build_parent_dir + 'libgit2-' + libgit2_settings.version %}
    {% set libgit2_build_dir = libgit2_src_dir + '/_build' %}

    {% if libssh2_settings.install_from_source %}
      {% set libssh2_src_dir   = libssh2_settings.build_parent_dir + 'libssh2-' + libssh2_settings.version %}
      {% set libssh2_build_dir = libssh2_src_dir + '/_build' %}
dl-libssh2-src:
  archive.extracted:
    - name: {{ libssh2_settings.build_parent_dir }}
    - source: https://github.com/libssh2/libssh2/releases/download/libssh2-{{ libssh2_settings.version }}/libssh2-{{ libssh2_settings.version }}.tar.gz
    - source_hash: md5={{ libssh2_settings.download_hash }}
    - archive_format: tar
    - keep: True
    - if_missing: /usr/src/libssh2-{{ libssh2_settings.version }}

{{ libssh2_build_dir }}:
  file.directory

configure-libssh2:
  cmd.run:
    - name: cmake ..
    - cwd: {{ libssh2_build_dir }}
    - creates: {{ libssh2_build_dir }}/Makefile

build-libssh2:
  cmd.run:
    - name: make -j4
    - cwd: {{ libssh2_build_dir }}
    - creates: {{ libssh2_build_dir }}/libssh2.so

install-libssh2:
  cmd.run:
    - name: make install
    - cwd: {{ libssh2_build_dir }}
    - creates: /usr/local/lib/libssh2.so
    - watch_in:
      - cmd: run-ldconfig-after-lib-install

    {% endif %}

dl-libgit2-src:
  archive.extracted:
    - name: {{ libgit2_settings.build_parent_dir }}
    - source: https://github.com/libgit2/libgit2/archive/v{{ libgit2_settings.version }}.tar.gz
    - source_hash: md5={{ libgit2_settings.download_hash }}
    - archive_format: tar
    - keep: True
    - if_missing: /usr/src/libgit2-{{ libgit2_settings.version }}

{{ libgit2_build_dir }}:
  file.directory

configure-libgit2:
  cmd.run:
    - name: cmake ..
    - cwd: {{ libgit2_build_dir }}
    - creates: {{ libgit2_build_dir }}/Makefile

build-libgit2:
  cmd.run:
    - name: make -j4
    - cwd: {{ libgit2_build_dir }}
    - creates: {{ libgit2_build_dir }}/libgit2.so

install-libgit2:
  cmd.run:
    - name: make install
    - cwd: {{ libgit2_build_dir }}
    - creates: /usr/local/lib/libgit2.so
    - watch_in:
      - cmd: run-ldconfig-after-lib-install

run-ldconfig-after-lib-install:
  cmd.wait:
    - name: ldconfig

  {% else %}
{{ salt_settings.libgit2 }}:
  pkg.installed

  {% endif %}

install-pygit2:
  pip.installed:
    - name: pygit2 == {{ pygit2_settings.version }}
    - require:
      - pkg: pygit2-deps

{% else %}
{{ salt_settings.pygit2 }}:
  pkg.installed
{% endif %}
