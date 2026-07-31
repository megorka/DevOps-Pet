resource "yandex_vpc_network" "net" {
  name = "test-network"
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {

  }
}

resource "yandex_vpc_route_table" "nat_route" {
  network_id = yandex_vpc_network.net.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "test-public-subnet"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_vpc_subnet" "private_subnet" {
  name           = "test-private-subnet"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.1.0/24"]
  route_table_id = yandex_vpc_route_table.nat_route.id
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
  ingress {
    protocol       = "TCP"
    description    = "Kuber"
    port           = 6443
    v4_cidr_blocks = ["10.0.0.0/23"]
  }
  ingress {
    protocol = "TCP"
    description = "ports"
    from_port = 30000
    to_port = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "TCP"
    description = "API kuber"
    port = 10250
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "UDP"
    description = "UDP"
    port = 8472
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol = "TCP"
    description = "Kubers"
    port = 10248
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "ANY"
    description    = "for blocking any port"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "test" {
  count = 3
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
    user-data = var.meta_file
  }
  name = "test-${count.index}"
  network_interface {
    subnet_id          = count.index == 0 ? yandex_vpc_subnet.public_subnet.id : yandex_vpc_subnet.private_subnet.id
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

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/ansible/inventory.ini"
  content = templatefile("${path.module}/templates/inventory.tpl", {
    master_ip  = yandex_compute_instance.test[0].network_interface[0].nat_ip_address
    master_ip_internal = yandex_compute_instance.test[0].network_interface[0].ip_address
    worker_ips = [for i in yandex_compute_instance.test : i.network_interface[0].ip_address if i != yandex_compute_instance.test[0]]
  })
}