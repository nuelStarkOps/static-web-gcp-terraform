# Cloud Storage Bucket
resource "google_storage_bucket" "website" {
  name = "static-web-terraform-gcp"
  location = "US"
}

# Grant public access to viee Bucket objeects
resource "google_storage_object_access_control" "public_rule" {
  object = google_storage_bucket_object.object.output_name
  bucket = google_storage_bucket.bucket.name
  role   = "READER"
  entity = "allUsers"
}

# Cloud Storage Bucket Object (Static Website)
resource "google_storage_bucket_object" "website_file" {
    name = "index.html"
    bucket = google_storage_bucket.website.name
    source = "../website/index.html"
}