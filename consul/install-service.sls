{%- from slspath+"/map.jinja" import consul with context -%}

include:
  - {{ slspath }}.service

consul-init-env:
  file.managed:
    {%- if grains['os_family'] == 'Debian' %}
    - name: /etc/default/consul
    {%- else %}
    - name: /etc/sysconfig/consul
    - makedirs: True
    {%- endif %}
    - user: root
    - group: root
    - mode: 0644
    - contents:
      - CONSUL_USER={{ consul.user }}
      - CONSUL_GROUP={{ consul.group }}
{%- if consul.service %}
    - watch_in:
      - service: consul-service
{%- endif %}

consul-init-file:
  file.managed:
    {%- if salt['test.provider']('service').startswith('systemd') %}
    - source: salt://{{ slspath }}/files/consul.service
    - name: /etc/systemd/system/consul.service
    - template: jinja
    - context:
        user: {{ consul.user }}
        group: {{ consul.group }}
    - mode: 0644
    {%- elif salt['test.provider']('service') == 'upstart' %}
    - source: salt://{{ slspath }}/files/consul.upstart
    - name: /etc/init/consul.conf
    - mode: 0644
    {%- else %}
    - source: salt://{{ slspath }}/files/consul.sysvinit
    - name: /etc/init.d/consul
    - mode: 0755
    {%- endif %}
{%- if consul.service %}
    - watch_in:
      - service: consul-service
{%- endif %}
