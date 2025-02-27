# Load Balancer - Reserve External Ip Address for Static Ip
resource "google_compute_global_address" "website_ip" {
  name = "website-lb-ip"
}

data "google_dns_managed_zone" "dns_zone" {
  name    = "terraform-gcp"
  project = var.gcp_project_id
}

resource "google_dns_record_set" "website" {

  name = "xyz.${data.google_dns_managed_zone.dns_zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}


# #  Add the bucket as a CDN backend
resource "google_compute_backend_bucket" "website_backend" {
  name        = "website-bucket"
  description = "Contains Website Files"
  bucket_name = google_storage_bucket.website.name
  enable_cdn  = true
}


# # GCP URL Map - allows to specify traffic direction from customer to CDN bucket
resource "google_compute_url_map" "urlmap" {
  name        = "urlmap"
  description = "urlmap for customer traffic"

  default_service = google_compute_backend_bucket.website_backend.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website_backend.self_link
  }
}

# GCP HTTP Proxy 
resource "google_compute_target_http_proxy" "website_proxy" {
  name        = "website-proxy"
  url_map     = google_compute_url_map.urlmap.self_link
  description = "a description"
}

# #GCP Forwarding Rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "website-forwarding-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website_ip.address
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_http_proxy.website_proxy.self_link
}


