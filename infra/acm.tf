# Import existing ACM Certificate
data "aws_acm_certificate" "website" {
  domain   = "connor.couetil.com"
  statuses = ["ISSUED"]
}
