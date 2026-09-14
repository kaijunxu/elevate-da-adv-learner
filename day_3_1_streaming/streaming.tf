# =====================================================================
# Data for resources already created in shared infra
# =====================================================================

# Project number for service agent IAM permissions
data "google_project" "project" {
  project_id = var.project_id
}

# Module service account
data "google_service_account" "cymbal_sa_data" {
  account_id = "cymbal-sa-data"
}

# BigQuery datasets
data "google_bigquery_dataset" "cymbal_bronze" {
  dataset_id = var.dataset_id_bronze
  project    = var.project_id
}

data "google_bigquery_dataset" "cymbal_silver" {
  dataset_id = var.dataset_id_silver
  project    = var.project_id
}

data "google_bigquery_dataset" "cymbal_gold" {
  dataset_id = var.dataset_id_gold
  project    = var.project_id
}

# VPC network and subnetwork
data "google_compute_network" "cymbal_network" {
  name    = "cymbal-retail-vpc"
  project = var.project_id
}

data "google_compute_subnetwork" "cymbal_subnet" {
  name    = "cymbal-retail-subnet-${var.gcp_region}"
  region  = var.gcp_region
  project = var.project_id
}

# =====================================================================
# Lab 2.1 resources
# =====================================================================

data "external" "bootstrap_address" {
  program = [
    "python3",
    "-c",
    "import subprocess, json; val=subprocess.check_output(['gcloud', 'managed-kafka', 'clusters', 'describe', '${var.kafka_cluster_id}', '--location=${var.gcp_region}', '--format=value(bootstrapAddress)', '--project=${var.project_id}']).decode().strip(); print(json.dumps({'bootstrap_address': val}))"
  ]
}

# Compute Engine instance for Kafka client
resource "google_compute_instance" "kafka_client" {
  name         = "kafka-client"
  machine_type = "e2-standard-2"
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-13"
    }
  }

  network_interface {
    subnetwork = data.google_compute_subnetwork.cymbal_subnet.id
  }

  service_account {
    email  = data.google_service_account.cymbal_sa_data.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    mkdir -p /opt/kafka-client
    gcloud storage cp gs://kaijun-elevate-kafka-client/stream_pos_generator.py /opt/kafka-client/stream_pos_generator.py
    gcloud storage cp gs://kaijun-elevate-kafka-client/stream_pos_requirements.txt /opt/kafka-client/stream_pos_requirements.txt
    apt-get update
    apt install -y python3-pip
    pip install -r /opt/kafka-client/stream_pos_requirements.txt --break-system-packages
    chmod -R 755 /opt/kafka-client

    # Write systemd service file
    cat <<'SERVICE_EOF' > /etc/systemd/system/retail-producer.service
[Unit]
Description=Streaming POS Producer Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/kafka-client
ExecStart=/usr/bin/python3 /opt/kafka-client/stream_pos_generator.py --bootstrap_servers ${data.external.bootstrap_address.result.bootstrap_address} --topic pos-transactions
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    systemctl daemon-reload
    systemctl enable retail-producer.service
    systemctl start retail-producer.service
  EOF

  depends_on = [
    data.external.bootstrap_address,
  ]
}

# TODO - create your resources here


# =====================================================================
# Lab 2.2 resources to be created (not in starter code)
# =====================================================================

# TODO - create your resources here

