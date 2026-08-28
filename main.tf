terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

locals {
  repo_name = "github-terraform-task-solution"
  user_name = "softservedata"
  pr_tmplt_content = <<EOT
    ## Describe your changes

    ## Issue ticket number and link

    ## Checklist before requesting a review
    - [ ] I have performed a self-review of my code
    - [ ] If it is a core feature, I have added thorough tests
    - [ ] Do we need to implement analytics?
    - [ ] Will this be part of a product update? If yes, please write one phrase about this update
  EOT
}

resource "github_branch" "develop_branch" {
  repository = local.repo_name
  branch     = "develop"
}

resource "github_branch_default" "develop_branch_default" {
  repository = local.repo_name
  branch     = github_branch.develop_branch.branch
}

resource "github_repository_collaborator" "a_repo_collaborator" {
  repository = local.repo_name
  username   = local.user_name
  permission = "push"
}

resource "github_branch_protection" "main_protect_rules" {
  repository_id = local.repo_name
  pattern       = "main"

  required_pull_request_reviews {
    require_code_owner_reviews = true
    required_approving_review_count = 0
  }
}

resource "github_branch_protection" "develop_protect_rules" {
  repository_id = local.repo_name
  pattern       = "develop"

  required_pull_request_reviews {
    required_approving_review_count = 2
  }
}

resource "github_repository_file" "codeowners" {
  repository          = local.repo_name
  branch              = "main"
  file                = ".github/CODEOWNERS"
  content             = "* @softservedata"
  overwrite_on_create = true
}

resource "github_repository_file" "main_pr_template" {
  repository          = local.repo_name
  branch              = "main"
  file                = ".github/pull_request_template.md"
  content             = local.pr_tmplt_content
  overwrite_on_create = true
}

resource "github_repository_file" "develop_pr_template" {
  repository          = local.repo_name
  branch              = "develop"
  file                = ".github/pull_request_template.md"
  content             = local.pr_tmplt_content
  overwrite_on_create = true
  depends_on          = [github_branch.develop_branch]
}

resource "github_repository_webhook" "discord_webhook" {
  repository = local.repo_name

  configuration {
    url          = "https://discord.com/api/webhooks/1542905457218429023/DVlMB9wjFTWBmkAmDGTKxVbCxlVKr9bBpqNvGtK4pUQPZ3f_7YpZA_xdAzG-QCK6bm_S/github"
    content_type = "application/json"
  }

  events = ["pull_request"]
}

resource "github_repository_deploy_key" "repository_deploy_key" {
  title      = "DEPLOY_KEY"
  repository = local.repo_name
  key        = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDXF47jxtSyS1vSK0T3viXZO5NYCVwLUrhslGuC+m6URqfN5Atmif7rmXeucQVQU9+eAPkmVGWKrI+BS396LcqmPfAtCEZB3fQtzO5nnUpS2HfLi1yT1FSAmNn+aqWJxAMxkISU7gVwetJPs1P8+sfb/zD5+rAZmCLJ7VEjivYsT2RVpigGJwwkfKrgVSxxDkb0lnu+jjPwwfpemZ5P7gzRRM8afEkquqibO5fOhbNuOmWBSi5DojFfnvOa3VW3pXH9K45MpWe8q1cizTvho7H4fdDugGNhIccL8qBvUx3+cPlsKIw2J+G0l3rwKn+hWBh5FxiJKywwq7v2Brmf0OUSlSQQ0YxWZ4iPU/rjA24aSCj7UmxCU2G+dD4gbxjDTjenKqEXeEMQzM6xd9ULT/5b8LqAVDtMhRtixstfkPOAxPslJq11EvpW12JDk+miaqODaFEeCjxEmKNyk82DPRff1v51z9WVuCISuyh25fQ0XlknBY716bhCbg92q02uzOxGi+fCTaQVezW9YkA3Hm3TX+RF5FcbUkweC8yXqNpI1peFjSlV+45Te7UInq3KUQLuvoLDOs6b160rZqWdA5QYu/nZKF6QDF2m2J/CPd6abafN4d9RrD3lHGcXwApGZ3Vs9sJ+MJ10BttxPjhSDk7sZ/sHAVtHHjxkw3UT+5AezQ=="
}

resource "github_actions_secret" "pat_secret" {
  repository      = local.repo_name
  secret_name     = "PAT"
  plaintext_value = var.pat_token
}
