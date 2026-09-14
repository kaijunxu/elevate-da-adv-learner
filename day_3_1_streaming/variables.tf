variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "gcp_region" {
  description = "Default Google Cloud deployment region"
  type        = string
  default     = "us-central1"
}

# =====================================================================
# VARIABLES FOR RESOURCE IDENTIFIERS REFERENCED ACROSS LAB MODULES
# =====================================================================

# Service Account IDs
variable "cymbal_sa_data_id" {
  type    = string
  default = "cymbal-sa-data"
}

# BigQuery dataset IDs
variable "dataset_id_bronze" {
  type    = string
  default = "cymbal_bronze"
}
variable "dataset_id_silver" {
  type    = string
  default = "cymbal_silver"
}
variable "dataset_id_gold" {
  type    = string
  default = "cymbal_gold"
}

variable "kafka_cluster_id" {
  type    = string
  default = "kafka-cluster"
}

variable "kafka_connect_cluster_id" {
  type    = string
  default = "kafka-connect-cluster"
}

variable "order_anomaly_endpoint_name" {
  description = "Name of the Vertex AI endpoint for order anomaly detection"
  type        = string
  default     = "order-anomaly-endpoint"
}

variable "cashier_abuse_endpoint_name" {
  description = "Name of the Vertex AI endpoint for cashier abuse detection"
  type        = string
  default     = "cashier-abuse-endpoint"
}

