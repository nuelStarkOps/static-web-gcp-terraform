# Create HTTPS Certificate

resource "google_compute_managed_ssl_certificate" "website" {
  name = "website-cert"

  managed {
    domains = [google_dns_record_set.website.name]
  }
}