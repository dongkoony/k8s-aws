# ./outputs.tf

# master 스냅샷 ID 출력
output "master_snapshot_id" {
  value = aws_ebs_snapshot.k8s_snapshots["master"].id
}

# node1 스냅샷 ID 출력
output "node1_snapshot_id" {
  value = aws_ebs_snapshot.k8s_snapshots["node1"].id
}

# node2 스냅샷 ID 출력
output "node2_snapshot_id" {
  value = aws_ebs_snapshot.k8s_snapshots["node2"].id
}
