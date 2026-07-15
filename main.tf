
resource "yandex_compute_instance" "test" {
  boot_disk {
    initialize_params {
      name       = "disk-ubuntu-24-04-lts-1784117163428"
      type       = "network-ssd"
      size       = 20
      block_size = 4096
      image_id   = "fd8dcjve5vsdhbqs6nqj"
    }
    auto_delete = true
  }
  hostname = "test"
  metadata = {
    user-data               = "${file("meta.txt")}"
    private_ui_created_from = "console"
  }
  name = "test"
  network_interface {
    subnet_id = "fl8ngo4u1n5vipp6r6rj"
    index     = 0
    nat       = true
  }
  platform_id = "standard-v3"
  resources {
    memory        = 2
    cores         = 2
    core_fraction = 100
  }
  scheduling_policy {
    preemptible = false
  }
  zone = "ru-central1-d"
}