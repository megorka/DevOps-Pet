output "public_ip" {
  value = yandex_compute_instance.test[0].network_interface[0].nat_ip_address
}