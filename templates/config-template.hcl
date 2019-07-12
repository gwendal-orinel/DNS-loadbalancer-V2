consul {
  address = "127.0.0.1:80"
  token = "{{ item.master_token }}"
}
log_level = "warn"

template {
  source = "/var/consul/templates/ha.tmp"
  destination = "/tmp/ha.sh"
  command = "bash /tmp/ha.sh"
  backup = true
  left_delimiter  = "[["
  right_delimiter = "]]"
}
