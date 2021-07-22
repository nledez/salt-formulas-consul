{%- from slspath+"/map.jinja" import consul with context -%}

{%- if consul.service %}

consul-service:
  service.running:
    - name: consul
    - enable: True

{%- endif %}
