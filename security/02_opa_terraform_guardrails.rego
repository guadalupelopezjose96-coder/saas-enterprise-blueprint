package saas.enterprise.guardrails

# Control OPA-01: Prohibir terminantemente buckets S3 sin Object Lock WORM o sin cifrado KMS HSM
deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not resource.change.after.object_lock_enabled
    msg := sprintf("VIOLACION OPA-01 (ISO A.8.15): El bucket %v debe tener object_lock_enabled = true", [resource.name])
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_kms_key"
    not resource.change.after.enable_key_rotation
    msg := sprintf("VIOLACION OPA-01 (ISO A.8.24): La clave KMS %v debe tener rotacion automatica habilitada", [resource.name])
}
