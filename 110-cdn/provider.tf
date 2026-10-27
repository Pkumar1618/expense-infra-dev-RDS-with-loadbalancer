resource "aws_instance" "web_east" {
  provider = aws.east
  ami      = "ami-123456"
  instance_type = "t2.micro"
}

resource "aws_instance" "web_west" {
  provider = aws.west
  ami      = "ami-654321"
  instance_type = "t2.micro"
}

resource "google_compute_instance" "vm_instance" {
  name         = "my-google-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  provider     = google
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  network_interface {
    network = "default"
  }
}