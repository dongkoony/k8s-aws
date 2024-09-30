output "master_snapshot_id" {
  description = "k8s-master의 EBS 스냅샷 ID"
  value       = aws_ebs_snapshot.master_snapshot.id
}

output "node1_snapshot_id" {
  description = "k8s-node1의 EBS 스냅샷 ID"
  value       = aws_ebs_snapshot.node1_snapshot.id
}

output "node2_snapshot_id" {
  description = "k8s-node2의 EBS 스냅샷 ID"
  value       = aws_ebs_snapshot.node2_snapshot.id
}
