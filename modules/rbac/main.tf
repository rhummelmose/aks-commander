######################################################################### PROVIDERS
provider "azuread" {
  alias     = "rbac"
  tenant_id = var.rbac_aad_tenant_id
}

provider "azuread" {
  alias     = "cluster"
  tenant_id = var.cluster_aad_tenant_id
}

######################################################################### LOCALS
locals {
  redirect_url = "https://login.microsoftonline.com/common/oauth2/nativeclient"
}

######################################################################### CLUSTER
resource "azuread_application" "aks_cluster" {
  provider = azuread.cluster
  name = "${var.prefix}-aks-cluster-${var.suffix}"
  type = "native"
}

resource "azuread_service_principal" "aks_cluster" {
  provider = azuread.cluster
  application_id = azuread_application.aks_cluster.application_id
  # The following tag is required to make the service principal visible under enterprise applications in the portal
  tags = ["WindowsAzureActiveDirectoryIntegratedApp"]
}

resource "random_password" "aks_cluster_password" {
  length = 16
  special = true

  keepers = {
    azuread_application = azuread_application.aks_cluster.application_id
  }
}

resource "azuread_application_password" "aks_cluster_passwod" {
  provider = azuread.cluster
  application_object_id = azuread_application.aks_cluster.id
  value = random_password.aks_cluster_password.result

  end_date = timeadd(timestamp(), "87600h")

  lifecycle {
    ignore_changes = [
      "end_date"]
  }
}

######################################################################### SERVER
resource "azuread_application" "server" {
  provider = azuread.rbac
  name                    = "${var.prefix}-aks-cluster-server-${var.suffix}"
  reply_urls              = [local.redirect_url]
  type                    = "webapp/api"
  group_membership_claims = "All"

  required_resource_access {
    # Windows Azure Active Directory API
    resource_app_id = "00000002-0000-0000-c000-000000000000"

    resource_access {
      # DELEGATED PERMISSIONS: "Sign in and read user profile":
      # 311a71cc-e848-46a1-bdf8-97ff7156d8e6
      id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
      type = "Scope"
    }
  }

  required_resource_access {
    # MicrosoftGraph API
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    # APPLICATION PERMISSIONS: "Read directory data":
    # 7ab1d382-f21e-4acd-a863-ba3e13f7da61
    resource_access {
      id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61"
      type = "Role"
    }

    # DELEGATED PERMISSIONS: "Sign in and read user profile":
    # e1fe6dd8-ba31-4d61-89e7-88639da4683d
    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }

    # DELEGATED PERMISSIONS: "Read directory data":
    # 06da0dbc-49e2-44d2-8312-53f166ab848a
    resource_access {
      id   = "06da0dbc-49e2-44d2-8312-53f166ab848a"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "server" {
  provider = azuread.rbac
  application_id = azuread_application.server.application_id
  # The following tag is required to make the service principal visible under enterprise applications in the portal
  tags = ["WindowsAzureActiveDirectoryIntegratedApp"]
}

resource "azuread_application_password" "server" {
  provider = azuread.rbac
  application_object_id = azuread_application.server.id
  value = "${random_password.application_server_password.result}"
  end_date = "${timeadd(timestamp(), "87600h")}" # 10 years

  # The end date will change at each run (terraform apply), causing a new password to 
  # be set. So we ignore changes on this field in the resource lifecyle to avoid this
  # behaviour.
  # If the desired behaviour is to change the end date, then the resource must be
  # manually tainted.
  lifecycle {
    ignore_changes = ["end_date"]
  }
}

resource "random_password" "application_server_password" {
  length  = 16
  special = true

  keepers = {
    application = azuread_application.server.application_id
  }
}

######################################################################### CLIENT

resource "azuread_application" "client" {
  provider = azuread.rbac
  name       = "${var.prefix}-aks-cluster-client-${var.suffix}"
  reply_urls = [local.redirect_url]
  type       = "native"

  required_resource_access {
    # Windows Azure Active Directory API
    resource_app_id = "00000002-0000-0000-c000-000000000000"

    resource_access {
      # DELEGATED PERMISSIONS: "Sign in and read user profile":
      # 311a71cc-e848-46a1-bdf8-97ff7156d8e6
      id   = "311a71cc-e848-46a1-bdf8-97ff7156d8e6"
      type = "Scope"
    }
  }

  required_resource_access {
    # AKS ad application server
    resource_app_id = "${azuread_application.server.application_id}"

    resource_access {
      # Server app Oauth2 permissions id
      id   = "${lookup(azuread_application.server.oauth2_permissions[0], "id")}"
      type = "Scope"
    }
  }
}

resource "azuread_service_principal" "client" {
  provider = azuread.rbac
  application_id = azuread_application.client.application_id
  # The following tag is required to make the service principal visible under enterprise applications in the portal
  tags = ["WindowsAzureActiveDirectoryIntegratedApp"]
}

######################################################################### LOCAL-EXEC

resource "null_resource" "rbac_local_exec" {
  provisioner "local-exec" {
    command = <<EOF
    bash ${path.module}/scripts/verify_azure_cli.sh && \
    bash ${path.module}/scripts/verify_service_principals.sh ${azuread_service_principal.aks_cluster.id} ${azuread_service_principal.server.id} ${azuread_service_principal.client.id} && \
    bash ${path.module}/scripts/ensure_admin_consent.sh ${var.rbac_aad_tenant_id} ${azuread_service_principal.server.application_id} ${azuread_service_principal.client.application_id} \"$(printf '%s' '${random_password.application_server_password.result}')\"
    EOF
  }
}

data "external" "secret_in_out" {
  program = ["bash", "${path.module}/scripts/secret_in_out.sh"]
  query = {
    secret = random_password.application_server_password.result
  }
  depends_on = [
    null_resource.rbac_local_exec
  ]
}
