######################################################################### LOCAL-EXEC

resource "null_resource" "rbac_local_exec" {
  provisioner "local-exec" {
    command = <<EOF
    bash scripts/verify_azure_cli.sh && \
    bash scripts/verify_service_principals.sh 83536075-5c5e-4c20-af48-a9bbdee9d9cc 30ae8909-49b1-4fa0-98c2-5d0e83b60cf0 5b33e1f2-3fba-4cd5-a2c8-608857387862 && \
    bash scripts/ensure_admin_consent.sh df4931ba-151e-47bb-88fb-dc91741c15f7 23ce9ecf-e134-4432-b05d-e02f431c4c18 0d245d99-945b-40c1-8ae3-7e7549d1ef84 "$(printf '%s' 'N[196?J:Y?zuOQ$[}')"
    EOF
  }
}
