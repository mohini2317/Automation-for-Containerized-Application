
data "aws_caller_identity" "current" {}


variable "github_owner" {
  description = "GitHub repository owner"
  default = "mohini2317"
}

variable "github_repo" {
  default = "Automation-for-Containerized-Application"
  description = "GitHub repository name"
}

variable "github_branch" {
  default     = "main"
  description = "GitHub repository branch"
}
resource "aws_codestarconnections_connection" "github_connection" {
  name               = "github-connection"
  provider_type      = "GitHub"
}

resource "aws_codepipeline" "eks_codepipeline" {
  name     = "eks-deployment-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name             = "GitHub_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn = aws_codestarconnections_connection.github_connection.arn
        FullRepositoryId = "${var.github_owner}/${var.github_repo}"
        BranchName = var.github_branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      configuration = {
        ProjectName = aws_codebuild_project.eks_codebuild.name
      }
    }
  }
}

resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = "eks-codepipeline-bucket-demo1"
}

resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_policy" "codepipeline_additional_policy" {
  name        = "CodePipelineAdditionalPermissions"
  description = "Additional permissions for CodePipeline service role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "codestar-connections:UseConnection",
          "appconfig:StartDeployment",
          "appconfig:GetDeployment",
          "appconfig:StopDeployment",
          "codecommit:GetRepository"
        ],
        Resource = "*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_additional_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name  
  policy_arn = aws_iam_policy.codepipeline_additional_policy.arn
}
resource "aws_iam_policy" "codepipeline_policy" {
  name   = "codepipeline-policy"
  policy = data.aws_iam_policy_document.codepipeline_policy_doc.json
}

data "aws_iam_policy_document" "codepipeline_policy_doc" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.codepipeline_bucket.arn}",
      "${aws_s3_bucket.codepipeline_bucket.arn}/*"
    ]
  }

  statement {
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy_attachment" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}

resource "aws_codebuild_project" "eks_codebuild" {
  name          = "eks-codebuild-project"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = "5"
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:4.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = "application/buildspec.yaml" # Your buildspec file here
  }
}

resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "codebuild_policy" {
  name   = "codebuild-policy"
  policy = data.aws_iam_policy_document.codebuild_policy_doc.json
}

data "aws_iam_policy_document" "codebuild_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage", # Added this line
      "ecr:GetDownloadUrlForLayer",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = ["*"]
  }
   # Add this new statement for EKS DescribeCluster permission
  statement {
    actions = [
      "eks:*"
    ]
    resources = [
      "arn:aws:eks:ap-south-1:${data.aws_caller_identity.current.account_id}:cluster/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

