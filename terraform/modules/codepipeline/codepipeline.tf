resource "aws_codepipeline" "app" {
  name     = "${var.name_prefix}-bluegreen-deploy"
  role_arn = aws_iam_role.codepipeline.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.id
    type     = "S3"
  }

  /*
  stage {
    name = "Source"
    action {
      name             = "Clone_Repository_from_Github"
      namespace        = "SourceVariables"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        ConnectionArg        = var.github_connection_arn
        FullRepositoryId     = var.github_target_repo_name
        BranchName           = var.github_target_branch
        OutputArtifactFormat = "CODEBUILD_CLONE_REF"
        DetectChanges        = true
      }
    }
  }
*/
  stage {
    name = "Source"
    action {
      name             = "Source"
      namespace        = "SourceVariables"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        RepositoryName = aws_codecommit_repository.app.repository_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build_DockerImage_to_ECR"
      namespace        = "BuildVariables"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.app.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Blue_Green_Deployment_on_ECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeployToECS"
      region          = data.aws_region.current.name
      input_artifacts = ["BuildArtifact"]
      version         = "1"
      configuration = {
        ApplicationName                = aws_codedeploy_app.app.name
        DeploymentGroupName            = aws_codedeploy_deployment_group.app.deployment_group_name
        AppSpecTemplateArtifact        = "BuildArtifact"
        AppSpecTemplatePath            = "appspec.yml"
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath     = "taskdef.json"
        Image1ArtifactName             = "BuildArtifact"
        Image1ContainerName            = "IMAGE1_NAME"
      }
    }

    /*
    action {
      name             = "Test"
      category         = "Test"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArti"]
      version          = "1"
      configuration = {
        ProjectName          = aws_codebuild_project.app-test.name
        EnvironmentVariables = jsonencode([
          {
            name  = "BUCKET_NAME"
            type  = "PLAINTEXT"
            value = aws_s3_bucket.codepipeline_artifacts.id
          },
          {
            name  = "PIPELINE_EXECUTION_ID"
            type  = "PLAINTEXT"
            value = "#{codepipeline.PipelineExecutionId}"
          },
          {
            name  = "PIPELINE_NAME"
            type  = "PLAINTEXT"
            value = var.app
          }
        ])
      }
    }
*/
  }

  tags = var.tags
}


data "aws_region" "current" {}

data "aws_caller_identity" "current" {}
