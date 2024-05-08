set_timeservers:
  file.managed:
    - name: /etc/chrony.conf
    - source: salt://templates/cdw_chrony.conf
    - makedirs: True

  cmd.run:
    - name: systemctl start chronyd
    - require:
      - file: set_timeservers