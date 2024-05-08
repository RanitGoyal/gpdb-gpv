{% for username, user_details in pillar.get('users', {}).items() %}
{% set password = user_details.get('password') %}
{% set hash_password = user_details.get('hash_password', False) %}

add_{{ username }}_group:
  group.present:
    - name: {{ username }}

create_{{ username }}_user:
  user.present:
    - name: {{ username }}
    {% if hash_password %}
    - password: {{ salt['shadow.gen_password'](password) }}
    {% else %}
    - password: {{ password }}
    {% endif %}
    {% for key, value in user_details.items() if key != 'password' and key != 'hash_password' %}
    - {{ key }}: {{ value }}
    {% endfor %}
    - require:
      - group: add_{{ username }}_group
{% endfor %}