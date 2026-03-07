variable "bucket_name" {
  default = "dilbarpun-portfolio"
}

variable "region" {
  default = "ap-southeast-2"
}

variable "mime_types" {
  type = map(string)
  default = {
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".pdf"  = "application/pdf"
  }
}
