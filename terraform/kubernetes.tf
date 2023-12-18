data "google_client_config" "default" {
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

locals {
  subnetwork_name = module.vpc.subnets["${var.region}/${var.network.subnetwork_name}"].name
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "23.3.0"

  depends_on = [google_project_service.this["container"]]

  project_id = var.project_id
  region     = var.region

  name     = var.gke.name
  regional = var.gke.regional
  zones    = var.gke.zones

  network           = module.vpc.network_name
  subnetwork        = local.subnetwork_name
  ip_range_pods     = "${local.subnetwork_name}-pods"
  ip_range_services = "${local.subnetwork_name}-services"

  node_pools = [
    {
      name               = var.node_pool.name
      machine_type       = var.node_pool.machine_type
      disk_size_gb       = var.node_pool.disk_size_gb
      spot               = var.node_pool.spot
      initial_node_count = var.node_pool.initial_node_count
      max_count          = var.node_pool.max_count
      disk_type          = "pd-ssd"
    },
  ]

  network_policy             = true
  horizontal_pod_autoscaling = true
  http_load_balancing        = true
  create_service_account     = false

  remove_default_node_pool = true
  initial_node_count       = 1

  service_account = google_service_account.this.email
}