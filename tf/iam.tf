variable "aws_account_number" {}

data "aws_iam_policy_document" "trust_doc" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", "ecs-tasks.amazonaws.com"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "teamcity_role" {
  name               = "teamcity_role"
  assume_role_policy = "${data.aws_iam_policy_document.trust_doc.json}"
}

resource "aws_iam_role_policy" "teamcity_role_policy" {
  name = "teamcity_policy"
  role = "${aws_iam_role.teamcity_role.id}"

   policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ReadSettingsFromSSM",
            "Effect": "Allow",
            "Action": [
                      "ssm:GetParameter*"
            ],
            "Resource": [
                        "arn:aws:ssm:eu-west-1:${var.aws_account_number}:parameter/uk/arcade/apps/teamcity*",
                        "arn:aws:ssm:eu-west-1:${var.aws_account_number}:parameter/uk/shared/certs*"
            ]
        }
    ]
}
  POLICY
}

resource "aws_iam_role" "teamcity_service_role" {
  name               = "teamcity_service_role"
  assume_role_policy = "${data.aws_iam_policy_document.trust_doc.json}"
}

resource "aws_iam_role_policy" "teamcity_service_role_policy" {
  name = "teamcity_service_policy"
  role = "${aws_iam_role.teamcity_service_role.id}"

   policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ECSTaskManagement",
            "Effect": "Allow",
            "Action": [
                "ec2:AttachNetworkInterface",
                "ec2:CreateNetworkInterface",
                "ec2:CreateNetworkInterfacePermission",
                "ec2:DeleteNetworkInterface",
                "ec2:DeleteNetworkInterfacePermission",
                "ec2:Describe*",
                "ec2:DetachNetworkInterface",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:RegisterTargets",
                "route53:ChangeResourceRecordSets",
                "route53:CreateHealthCheck",
                "route53:DeleteHealthCheck",
                "route53:Get*",
                "route53:List*",
                "route53:UpdateHealthCheck",
                "servicediscovery:DeregisterInstance",
                "servicediscovery:Get*",
                "servicediscovery:List*",
                "servicediscovery:RegisterInstance",
                "servicediscovery:UpdateInstanceCustomHealthStatus"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ECSTagging",
            "Effect": "Allow",
            "Action": [
                "ec2:CreateTags"
            ],
            "Resource": "arn:aws:ec2:*:*:network-interface/*"
        },
        {
            "Sid": "PassRole",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "${aws_iam_role.teamcity_role.arn}"
        }
    ]
}
  POLICY
}
