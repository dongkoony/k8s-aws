# ./outputs.tf

output "master_ip" {
  description = "Master node public IP"
  value       = aws_instance.k8s_master.public_ip
}

output "worker_ips" {
  description = "Worker nodes public IPs"
  value = {
    node1 = aws_instance.k8s_workers[0].public_ip
    node2 = aws_instance.k8s_workers[1].public_ip
  }
}

# # 필요한 경우 스냅샷 ID도 출력할 수 있습니다
# output "master_snapshot_id" {
#   description = "Master node EBS snapshot ID"
#   value       = aws_ebs_snapshot.master_snapshot.id
# }

# output "worker_snapshot_ids" {
#   description = "Worker nodes EBS snapshot IDs"
#   value = {
#     node1 = aws_ebs_snapshot.worker_snapshots[0].id
#     node2 = aws_ebs_snapshot.worker_snapshots[1].id
#   }
# }
