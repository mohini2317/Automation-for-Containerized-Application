resource "aws_dynamodb_table" "persist_data" {
  name         = "aritra_eks_demo"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Assuming the email is a top-level attribute in your items
  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name               = "EmailIndex"
    hash_key           = "email"
    projection_type    = "ALL"  # Adjust according to your needs
    read_capacity      = 10     # Required if billing_mode is not PAY_PER_REQUEST
    write_capacity     = 10     # Required if billing_mode is not PAY_PER_REQUEST
  }
}
