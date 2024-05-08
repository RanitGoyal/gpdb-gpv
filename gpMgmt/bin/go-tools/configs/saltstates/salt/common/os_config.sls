# Deactivate or configure SELinux
disable_selinux:
  selinux.mode:
    - name: disabled


# Deactivate or configure Firewall
stop_and_disable_firewall:
  cmd.run:
    - name: |
        systemctl stop firewalld && systemctl disable firewalld
        systemctl stop tuned && systemctl disable tuned
        systemctl stop sssd && systemctl disable sssd
        systemctl stop sssd-kcm.socket && systemctl disable sssd-kcm.socket
    - require:
      - disable_selinux
 

# Add Boot Parameters
add_boot_parameters:
  cmd.run:
    - name: |
        /usr/sbin/grubby --update-kernel=ALL  --args="transparent_hugepage=never"
        /usr/sbin/grubby --update-kernel=ALL --args="elevator=deadline"
    - require:
      - stop_and_disable_firewall


# sysctl.conf file
create_sysctl_conf_file:
  file.managed:
    - name: /etc/sysctl.d/99-gpdb.conf
    - source: salt://templates/sysctl.conf
    - makedirs: True
  
  cmd.run:
   - name: /usr/sbin/sysctl -p /etc/sysctl.d/99-gpdb.conf
   - require:
     - file: create_sysctl_conf_file
#TODO: Additional calculation still needs to be done for values of "vm.min_free_kbytes", "kernel.shmmax", "kernel.shmall" as per RAM size of remote host

# System resource limits
set_resource_limits:
  file.managed:
    - name: /etc/security/limits.d/20-nproc.conf
    - source: salt://templates/limits.conf
    - makedirs: True

 
#modify_sshd_config
{% set sshd_config = '/etc/ssh/sshd_config' %}

{% for key, value in salt['pillar.get']('sshd_config', {}).items() %}
edit_{{ key }}_line:
  file.replace:
    - name: {{ sshd_config }}
    - pattern: '^{{ key }}.*'
    - repl: '{{ key }} {{ value }}'
    - append_if_not_found: True
{% endfor %}

modify_sshd_config:
  file.replace:
   - name: /etc/ssh/sshd_config
   - pattern: "^Ciphers .*$"
   - repl: ""

# Systemd Conf
set_system_conf:
  file.managed:
   - name: /etc/systemd/system.conf
   - mode: 644
   - replace: True
   - contents:
     - DefaultLimitNOFILE=65536


# Set time servers
# install ntp if not already there
install_chrony:
  pkg.installed:
    - name: chrony

#chrony configuration defined separately for coordinator and segments as content is different.