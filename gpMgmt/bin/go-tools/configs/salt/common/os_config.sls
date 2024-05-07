# Deactivate or configure SELinux
disable_selinux:
  selinux.mode:
    - name: disabled


# Deactivate or configure Firewall
stop_and_disable_firewall:
  cmd.run:
    - name: systemctl stop firewalld && systemctl disable firewalld
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

# Core Dump settings added to both sysctl.conf and limits.conf
# sysctl.conf file
#TODO
create_sysctl_conf_file:
  file.managed:
    - name: /etc/sysctl.d/99-gpdb.conf
    - source: salt://files/sysctl.conf
#NOTE: Additional calculation still needs to be done for values of "vm.min_free_kbytes", "kernel.shmmax", "kernel.shmall" as per RAM size of remote host
# System resource limits
set_resource_limits:
  file.managed:
    - name: /etc/security/limits.d/20-nproc.conf
    - source: salt://files/limits.conf



# Systemd Conf
set_system_conf:
  file.managed:
   - name: /etc/systemd/system.conf
   - replace: True
   - contents:
     - DefaultLimitNOFILE=65536


# Sshd config
# Example replace line in file
 
modify_sshd_config1:
  file.replace:
   - name: /etc/ssh/sshd_config
   - pattern: "^ChallengeResponseAuthentication .*$"
   - repl: "ChallengeResponseAuthentication yes"
   - append_if_not_found: True

# Set time servers
# install ntp if not already there
install_chrony:
  pkg.installed:
    - name: chrony
 
set_timeservers:
  file.managed:
    - name: /etc/chrony.conf  
    - contents: |
       makestep 1.0 3
       rtcsync
       logdir /var/log/chrony
 
       server cdw prefer
    - require:
      - install_chrony
 
#Need to run chrony configuration separately for coordinator and segments as content is different