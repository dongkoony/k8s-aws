# locals {
#   snapshot_ids = {
#     master = try(data.aws_ebs_snapshot.master_snapshot.id, null)
#     node1  = try(data.aws_ebs_snapshot.node1_snapshot.id, null)
#     node2  = try(data.aws_ebs_snapshot.node2_snapshot.id, null)
#   }
# }

# # 스냅샷 존재 여부 확인을 위한 locals
# locals {
#   master_snapshot_filter = {
#     name   = "tag:Name"
#     values = ["k8s-master-snapshot"]
#   }
#   node1_snapshot_filter = {
#     name   = "tag:Name"
#     values = ["k8s-node1-snapshot"]
#   }
#   node2_snapshot_filter = {
#     name   = "tag:Name"
#     values = ["k8s-node2-snapshot"]
#   }
# }

locals {
  key_destination = "/home/ubuntu/${var.key_name}"
}