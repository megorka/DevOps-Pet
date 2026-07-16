resource "yandex_vpc_network" "net" {
  name = "test-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "test-subnet"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_vpc_security_group" "test-sg" {
  name       = "test-sg"
  network_id = yandex_vpc_network.net.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "ANY"
    description    = "for blocking any port"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "test" {
  count = 1
  boot_disk {
    initialize_params {
      name       = "disk-ubuntu-24-04-lts-1784117163428--${count.index}"
      type       = "network-ssd"
      size       = 20
      block_size = 4096
      image_id   = data.yandex_compute_image.ubuntu.id
    }
    auto_delete = true
  }
  hostname = "test-${count.index}"
  metadata = {
    user-data = "${file("meta.txt")}"
  }
  name = "test-${count.index}"
  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet.id
    index              = 0
    nat                = count.index == 0 ? true : false
    security_group_ids = [yandex_vpc_security_group.test-sg.id]
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