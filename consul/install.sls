{%- from slspath + '/map.jinja' import consul with context -%}

{%- set packages_upgrade = salt['pillar.get']('packages_upgrade', False) %}
{%- if packages_upgrade %}
  {%- set pkg_install_or_latest = 'pkg.latest' %}
{%- else %}
  {%- set pkg_install_or_latest = 'pkg.installed' %}
{%- endif %}

consul-dep-unzip:
  pkg.installed:
    - name: unzip

consul-bin-dir:
  file.directory:
    - name: /usr/local/bin
    - makedirs: True

# Create consul user
consul-group:
  group.present:
    - name: {{ consul.group }}
    {% if consul.get('group_gid', None) != None -%}
    - gid: {{ consul.group_gid }}
    {%- endif %}

consul-user:
  user.present:
    - name: {{ consul.user }}
    {% if consul.get('user_uid', None) != None -%}
    - uid: {{ consul.user_uid }}
    {% endif -%}
    - groups:
      - {{ consul.group }}
    - home: {{ salt['user.info'](consul.user)['home']|default(consul.config.data_dir) }}
    - createhome: False
    - system: True
    - require:
      - group: consul-group

# Create directories
consul-config-dir:
  file.directory:
    - name: /etc/consul.d
    - user: {{ consul.user }}
    - group: {{ consul.group }}
    - mode: 0750

consul-data-dir:
  file.directory:
    - name: {{ consul.config.data_dir }}
    - makedirs: True
    - user: {{ consul.user }}
    - group: {{ consul.group }}
    - mode: 0750

# Install agent
{% if consul.packaging == "zip" %}
consul-package-install-file-directory:
  file.directory:
    - name: /opt/consul/v{{ consul.version }}
    - makedirs: True

consul-download:
  file.managed:
    - name: /opt/consul/consul_{{ consul.version }}_linux_{{ consul.arch }}.zip
    - source: https://{{ consul.download_host }}/consul/{{ consul.version }}/consul_{{ consul.version }}_linux_{{ consul.arch }}.zip
    - source_hash: https://releases.hashicorp.com/consul/{{ consul.version }}/consul_{{ consul.version }}_SHA256SUMS
    - unless: test -f /opt/consul/v{{ consul.version }}/consul-{{ consul.version }}

consul-extract:
  cmd.wait:
    - name: unzip /opt/consul/consul_{{ consul.version }}_linux_{{ consul.arch }}.zip -d /opt/consul/v{{ consul.version }}
    - watch:
      - file: consul-download

consul-install:
  file.symlink:
    - name: /usr/local/bin/consul
    - target: /opt/consul/v{{ consul.version }}/consul
    - force: true
{% elif consul.packaging == "debian" %}
/opt/consul/:
  file.absent: []

/usr/local/bin/consul:
  file.absent: []

/usr/share/keyrings/hashicorp-archive-keyring.gpg:
    file.managed:
    - source: salt://{{ slspath }}/files/hashicorp-archive-keyring.gpg
    - user: root
    - group: root
    - mode: 644
    - template: jinja

/etc/apt/sources.list.d/hashicorp.list:
  file.managed:
    - contents: "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] {{ consul.debian_mirror }} {{ grains['lsb_distrib_codename'] | lower }} main"
    - require:
      - file: /usr/share/keyrings/hashicorp-archive-keyring.gpg
    - onchanges_in:
      - cmd: hashicorp_apt_update

hashicorp_apt_update:
  cmd.run:
    - name: apt-get -q=9 update
    - stateful: False

consul-package:
  {{ pkg_install_or_latest }}:
    - pkgs:
      - consul={{ consul.version }}

/etc/consul.d/consul.hcl:
  file.absent: []
{% endif %}

# consul-install:
#   file.rename:
#     - name: /usr/local/bin/consul-{{ consul.version }}
#     - source: /opt/consul/consul
#     - require:
#       - file: /usr/local/bin
#     - watch:
#       - cmd: consul-extract

# consul-clean:
#   file.absent:
#     - name: /opt/consul/consul_{{ consul.version }}_linux_{{ consul.arch }}.zip
#     - watch:
#       - file: consul-install

# consul-link:
#   file.symlink:
#     - target: consul-{{ consul.version }}
#     - name: /usr/local/bin/consul
#     - watch:
#       - file: consul-install
