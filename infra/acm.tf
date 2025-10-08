# ACM Certificate for couetil.com and www.couetil.com
# Must be in us-east-1 for CloudFront
resource "aws_acm_certificate" "website" {
  provider          = aws
  domain_name       = "couetil.com"
  validation_method = "DNS"

  subject_alternative_names = ["www.couetil.com", "connor.couetil.com"]

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "couetil.com website"
  }
}
