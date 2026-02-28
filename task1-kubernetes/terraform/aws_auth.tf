# If the aws-auth ConfigMap already exists the apply will fail with
# "configmaps \"aws-auth\" already exists".  Import it before applying:
#
#   terraform import kubernetes_config_map_v1.aws_auth kube-system/aws-auth
#
# This mapping is required to allow nodes to register and grant the bastion
# IAM role cluster-admin privileges.

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.main.name
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.main.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = aws_iam_role.eks_nodes.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = aws_iam_role.bastion.arn
        username = "bastion"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [aws_eks_node_group.main, aws_eks_cluster.main]

  lifecycle {
    # prevent terraform from trying to destroy the map if the cluster is
    # deleted externally; generally the map should be managed by this
    # configuration only.
    prevent_destroy = true
  }
}
