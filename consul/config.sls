{%- from slspath + '/map.jinja' import consul with context -%}

consul-config:
  file.managed:
    - name: /etc/consul.d/config.json
    - user: {{ consul.user }}
    - group: {{ consul.group }}
    - mode: 0640
    - source: salt://{{ slspath }}/files/template.json.jinja
    - template: jinja
    - context:
      content:
        {{ consul.config | yaml }}
    - check_cmd: /usr/local/bin/consul validate
    - tmp_ext: '.json'
    - require:
      - user: consul-user
    {%- if consul.service %}
    - watch_in:
       - service: consul
    {%- endif %}

{% for script in consul.scripts %}
consul-script-install-{{ loop.index }}:
  file.managed:
    - source: {{ script.source }}
    - name: {{ script.name }}
    - template: jinja
    - context: {{ script.get('context', {}) | yaml }}
    - user: {{ consul.user }}
    - group: {{ consul.group }}
    - mode: 0755
{% endfor %}

consul-script-config:
  file.managed:
    - name: /etc/consul.d/services.json
    - user: {{ consul.user }}
    - group: {{ consul.group }}
    - mode: 0640
    - source: salt://{{ slspath }}/files/template.json.jinja
    - template: jinja
    - context:
      content:
        services:
          {{ consul.register | yaml }}
    - check_cmd: /usr/local/bin/consul validate /etc/consul.d/config.json
    - tmp_ext: '.json'
    - require:
      - user: consul-user
    {% if consul.service != False %}
    - watch_in:
       - service: consul
    {% endif %}
