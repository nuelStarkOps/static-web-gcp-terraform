# Load Balancer - Reserve External Ip Address for Static Ip
resource "google_compute_global_address" "website_ip" {
  name = "website-lb-ip"
}

data "google_dns_managed_zone" "dns_zone" {
  name = "test-zone"
}

resource "google_dns_record_set" "website" {

  name         = "xyz.${data.google_dns_managed_zone.dns_zone.dns_name}"
  type        = "A"
  ttl          = 300

  managed_zone = data.google_dns_managed_zone.dns_zone.name
  rrdatas = [google_compute_global_address.website_ip.address]
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
  description = "a description"

  default_service = google_compute_backend_bucket.website_backend.self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name = "allpaths"
    default_service = google_compute_backend_bucket.website_backend.self_link
  }
}

# # GCP HTTP Proxy 

resource "google_compute_target_http_proxy" "website_proxy" {
    name        = "website-proxy"
    url_map     = google_compute_url_map.urlmap.self_link
    description = "a description"  
}

# #GCP Forwarding Rule
resource "google_compute_forwarding_rule" "default" {
  name                  = "website-forwarding-rule"
  provider              = google-beta
  region                = "europe-west1"
  depends_on            = [google_compute_subnetwork.proxy_subnet]
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_region_target_http_proxy.default.id
  network               = google_compute_network.ilb_network.id
  subnetwork            = google_compute_subnetwork.ilb_subnet.id
  network_tier          = "PREMIUM"
}