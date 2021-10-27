provider "aws" {
  region = "us-east-1"
}

locals {
  layer_name  = "layer"
  layers_path = "${path.module}/layers/python"
  runtime     = "python3.7"
}


resource "null_resource" "pip_install" {
  triggers = {
    requirements = base64sha256(file("${local.layers_path}/requirements.txt"))
  }

  provisioner "local-exec" {
    working_dir = local.layers_path
    command     = "pip install -r requirements.txt --target . --no-user"
  }
}

data "archive_file" "source" {
  type        = "zip"
  source_dir  = local.layers_path
  output_path = "${local.layers_path}/${local.layer_name}.zip"

  depends_on = [null_resource.pip_install]
}

resource "aws_lambda_layer_version" "this" {
  filename         = "${local.layers_path}/${local.layer_name}.zip"
  layer_name       = local.layer_name
  description      = "layer"
  source_code_hash = data.archive_file.source.output_base64sha256

  compatible_runtimes = [local.runtime]

  depends_on = [null_resource.pip_install]
}
