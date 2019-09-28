######################################################################### PROVIDERS
provider "azuread" {
}

######################################################################### LOCALS
locals {
  redirect_url = "https://login.microsoftonline.com/common/oauth2/nativeclient"
}

######################################################################### CLUSTER
resource "azuread_application" "aks_cluster" {
  name = "${var.name}-aks-cluster"
  type = "native"
}

resource "azuread_service_principal" "aks_cluster" {
  application_id = azuread_application.aks_cluster.application_id
  # The following tag is required to make the service principal visible under enterprise applications in the portal
  tags = ["WindowsAzureActiveDirectoryIntegratedApp"]
}

resource "random_string" "aks_cluster_password" {
  length = 16
  special = false

  keepers = {
    azuread_application = azuread_application.aks_cluster.application_id
  }
}

resource "azuread_application_password" "aks_cluster_passwod" {
  application_object_id = azuread_application.aks_cluster.id
  value = random_string.aks_cluster_password.result

  end_date = timeadd(timestamp(), "87600h")

  lifecycle {
    ignore_changes = [
      "end_date"]
  }
}

######################################################################### SERVER
resource "azuread_application" "server" {
  name                    = "${var.name}-aks-cluster-server"
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
  application_id = azuread_application.server.application_id
  # The following tag is required to make the service principal visible under enterprise applications in the portal
  tags = ["WindowsAzureActiveDirectoryIntegratedApp"]
}

resource "azuread_application_password" "server" {
  application_object_id = azuread_application.server.id
  value = "${random_string.application_server_password.result}"
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

resource "random_string" "application_server_password" {
  length  = 16
  special = true

  keepers = {
    application = azuread_application.server.application_id
  }
}

######################################################################### CLIENT

resource "azuread_application" "client" {
  name       = "${var.name}-aks-cluster-client"
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
  application_id = azuread_application.client.application_id
  # The following tag is required to make the service principal visible under enterprise applications in the portal
  tags = ["WindowsAzureActiveDirectoryIntegratedApp"]
}
