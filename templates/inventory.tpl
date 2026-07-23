[k3s_master]
${master_ip} ansible_host=${master_ip} ansible_user=deploy ansible_port=22
[k3s_worker]
%{ for ip in worker_ips ~}
${ip} ansible_host=${ip} ansible_user=deploy ansible_ssh_common_args='-o ProxyJump=deploy@${master_ip}'
%{ endfor ~}

[vps:children]
k3s_master
k3s_worker