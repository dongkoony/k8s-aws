# tools/aws/ec2.py
import boto3

def list_ec2_instances(region: str = None) -> dict:
    """
    지정된(region) 또는 기본 리전의 EC2 인스턴스 목록과 상태를 조회합니다.
    """
    try:
        ec2 = boto3.client("ec2", region_name=region) if region else boto3.client("ec2")
        data = []
        for res in ec2.describe_instances().get("Reservations", []):
            for inst in res.get("Instances", []):
                name = next((t["Value"] for t in inst.get("Tags", []) if t["Key"]=="Name"), "Unnamed")
                data.append({
                    "instance_id": inst["InstanceId"],
                    "name": name,
                    "state": inst["State"]["Name"],
                    "instance_type": inst.get("InstanceType", ""),
                    "private_ip": inst.get("PrivateIpAddress", ""),
                    "public_ip": inst.get("PublicIpAddress", "")
                })
        return {"status": "success", "instances": data}
    except Exception as e:
        return {"status": "error", "message": str(e)}

def describe_ec2_instance(instance_id: str, region: str = None) -> dict:
    """
    특정 인스턴스(instance_id)의 상세 정보를 반환합니다.
    """
    try:
        ec2 = boto3.client("ec2", region_name=region) if region else boto3.client("ec2")
        resp = ec2.describe_instances(InstanceIds=[instance_id])
        inst = resp["Reservations"][0]["Instances"][0]
        name = next((t["Value"] for t in inst.get("Tags", []) if t["Key"]=="Name"), "Unnamed")
        return {
            "status": "success",
            "details": {
                "instance_id": inst["InstanceId"],
                "name": name,
                "state": inst["State"]["Name"],
                "launch_time": inst.get("LaunchTime").isoformat(),
                "instance_type": inst.get("InstanceType"),
                "private_ip": inst.get("PrivateIpAddress"),
                "public_ip": inst.get("PublicIpAddress")
            }
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

def start_ec2_instance(instance_id: str, region: str = None) -> dict:
    """
    지정된 인스턴스를 시작(start)합니다.
    """
    try:
        ec2 = boto3.client("ec2", region_name=region) if region else boto3.client("ec2")
        resp = ec2.start_instances(InstanceIds=[instance_id])
        st = resp["StartingInstances"][0]
        return {
            "status": "success",
            "previous_state": st["PreviousState"]["Name"],
            "current_state": st["CurrentState"]["Name"]
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}

def stop_ec2_instance(instance_id: str, region: str = None) -> dict:
    """
    지정된 인스턴스를 중지(stop)합니다.
    """
    try:
        ec2 = boto3.client("ec2", region_name=region) if region else boto3.client("ec2")
        resp = ec2.stop_instances(InstanceIds=[instance_id])
        st = resp["StoppingInstances"][0]
        return {
            "status": "success",
            "previous_state": st["PreviousState"]["Name"],
            "current_state": st["CurrentState"]["Name"]
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}
