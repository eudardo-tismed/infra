resource "aws_ecr_repository" "ecr_front" {
  name                 = "tismed-admin_app"
  image_tag_mutability = "MUTABLE"
}
