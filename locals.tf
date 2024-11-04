locals {
  snapshot_ids = {
    master = length(data.aws_ebs_snapshot.master_snapshot) > 0 ? data.aws_ebs_snapshot.master_snapshot[0].id : null,
    node1  = length(data.aws_ebs_snapshot.node1_snapshot) > 0 ? data.aws_ebs_snapshot.node1_snapshot[0].id : null,
    node2  = length(data.aws_ebs_snapshot.node2_snapshot) > 0 ? data.aws_ebs_snapshot.node2_snapshot[0].id : null
  }
}

locals {
  key_destination = "/home/ubuntu/${var.key_name}"
}