locals {
  key_destination = "/home/ubuntu/Project/${var.private_key_name}"
}

locals {
  k8s_sg_ingress = [
    { from_port=22,   to_port=22,   protocol="tcp", cidr_blocks=["0.0.0.0/0"], description="SSH" },
    { from_port=6443, to_port=6443, protocol="tcp", cidr_blocks=["0.0.0.0/0"], description="K8s API" },
    { from_port=2376, to_port=2376, protocol="tcp", cidr_blocks=["0.0.0.0/0"], description="Docker daemon" },
    { from_port=8080, to_port=8080, protocol="tcp", cidr_blocks=["0.0.0.0/0"], description="HTTP" },
    { from_port=8081, to_port=8081, protocol="tcp", cidr_blocks=["0.0.0.0/0"], description="Slack Flask Port" },
    { from_port=6274, to_port=6274, protocol="tcp", cidr_blocks=["0.0.0.0/0"], description="MCP Server" },
    { from_port=6277, to_port=6277, protocol="tcp", cidr_blocks=["0.0.0.0/0"], description="MCP Proxy" },
    { from_port=179,  to_port=179,  protocol="tcp", self=true,                 description="Calico BGP" },
    { from_port=0,    to_port=65535,protocol="tcp", self=true,                 description="Internal K8s TCP" },
    { from_port=0,    to_port=65535,protocol="udp", self=true,                 description="Internal K8s UDP" },
    { from_port=0,    to_port=0,    protocol="-1",  self=true,                 description="Internal ALL" },
  ]

  k8s_sg_egress = [
    { from_port=0, to_port=0, protocol="-1", cidr_blocks=["0.0.0.0/0"] }
  ]
}
