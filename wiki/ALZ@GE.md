# ALZ-Bicep Implementation

This file contains instructions for deploying the bicep-ALZ modules to a GEHC Azure AD Tenant.

## Prerequisites

Follow the prerequisite instructions in the [Enterprise Scale repo](https://github.com/Azure/Enterprise-Scale/wiki/Deploying-ALZ-Pre-requisites).

1. Initial user must have already been assigned global admin privileges, and privileges must be escalated to manage subscriptions (see the instructions above. This is done on the `aad/properties` screen)
2. Manually provision a bootstrap subscription
3. Login to the bootstrap subscription in a terminal:

  ```sh
  az login
  az account set --subscription '<subscription_id>'
  ```

4. Manually provision an Owner role assignment on the root tenant scope to the currently logged in users (there is no UI or bicep support for this task):

  ```sh
  az role assignment create --scope '/'  --role 'Owner' --assignee-object-id $(az ad signed-in-user show --query id --output tsv)
  ```

## 1. Management Group Hierarchy

The first step in the deployment sequence is to deploy the management group hierarchy. Modify the default management group hierarchy in the [local GEHC fork of Microsoft's ALZ-BICEP module](https://github.build.ge.com/hc-cto-alz/ALZ-Bicep/infra-as-code/bicep/modules/managementGroups/managementGroups.parameters.dev-gehc.json)

Then deploy the management group hierarchy:

  1. Prepare environment variables:

    ```sh
    env="dev0"
    MGID="gehc-${env}"
    dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
    NAME="${MGID}-MGDeployment-${dateYMD}"
    LOCATION="eastus2"
    TEMPLATEFILE="infra-as-code/bicep/modules/managementGroups/managementGroups.bicep"
    PARAMETERS="@infra-as-code/bicep/modules/managementGroups/parameters/managementGroups.parameters.dev-gehc.json"
```

  2. Test which resources will be provisioned by this deployment:

    ```sh
    az deployment tenant what-if --name ${NAME:0:63} --location $LOCATION --template-file $TEMPLATEFILE --parameters $PARAMETERS
```

  3. Deploy the management group hierarchy:

    ```sh
    az deployment tenant create --name ${NAME:0:63} --location $LOCATION --template-file $TEMPLATEFILE --parameters $PARAMETERS
```

## Custom Policy Definitions

After the management group hierarchy has been defined, the deployment sequence specifies deployment of custom policy and initiative definitions that supplement the built-in policies and initiatives to the "interim" root management group.

Start by adding any necessary additional policy and initiative definitions in the [GEHC ALZ-Bicep repo](https://github.com/Azure/ALZ-Bicep/tree/main/infra-as-code/bicep/modules/policy/definitions/lib).

Then deploy the custom policy definitions:

1. Prepare environment variables:

  ```sh
  env="dev0"
  MGID="gehc-${env}"
  dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
  NAME="${MGID}-PolicyDefsDefaults-${dateYMD}"
  LOCATION="eastus2"
  TEMPLATEFILE="infra-as-code/bicep/modules/policy/definitions/customPolicyDefinitions.bicep"
  PARAMETERS="@infra-as-code/bicep/modules/policy/definitions/parameters/customPolicyDefinitions.parameters.dev-gehc.json"
  ```

2. Test which resources will be provisioned by this deployment:

  ```sh
  az deployment mg what-if --name ${NAME:0:63} --location $LOCATION --management-group-id $MGID --template-file $TEMPLATEFILE --parameters $PARAMETERS
  ```

3. Deploy the custom policy and initiative definitions:

  ```sh
  az deployment mg create --name ${NAME:0:63} --location $LOCATION --management-group-id $MGID --template-file $TEMPLATEFILE --parameters $PARAMETERS
  ```

## Custom Role Definitions

After the custom policy and initiative definitions have been deployed to the "interim" root management group, the deployment sequence specifies deployment of custom roles.

> Note: this module is not as extensible as other ALZ modules. We can start with the standard ALZ roles, and fill in if we need to later.

To deploy the ALZ custom role assignments:

1. Prepare environment variables:

  ```sh
  dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
# For Azure global regions
env="dev0"
# Management Group ID
MGID="gehc-${env}"

# Chosen Azure Region
LOCATION="eastus2"
dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
NAME="${MGID}-CustomRoleDefsDeployment-${dateYMD}"
TEMPLATEFILE="infra-as-code/bicep/modules/customRoleDefinitions/customRoleDefinitions.bicep"
PARAMETERS="@infra-as-code/bicep/modules/customRoleDefinitions/parameters/customRoleDefinitions.parameters.dev-gehc.json"
  ```

2. Test which resources will be provisioned by this deployment:

  ```sh
  az deployment mg what-if --name ${NAME:0:63} --location $LOCATION --management-group-id $MGID --template-file $TEMPLATEFILE --parameters $PARAMETERS
  ```

3. Deploy the custom role definitions:

  ```sh
  az deployment mg create --name ${NAME:0:63} --location $LOCATION --management-group-id $MGID --template-file $TEMPLATEFILE --parameters $PARAMETERS
  ```

## Logging

After the custom role definitions have been deployed to the "interim" root management group, the deployment sequence specifies deployment of the central log analytics workspace and automation account.

> Note: This is the first time a subscription other than the bootstrap subscription is required.  For wasgehc.com, we're using the 523-gehc-management subscription ordered from CoreTech. For the devgehealthcare tenant, we are using the gehc-dev0-management subscription.

To deploy logging resources:

```sh
# For Azure Global regions
# Set Platform management subscripion ID as the the current subscription
ManagementSubscriptionId="a58e7ce8-a0c4-4f41-87f2-5677b9fcd5fd"
az account set --subscription $ManagementSubscriptionId

# Set the top level MG Prefix in accordance to your environment. This example assumes default 'alz'.
env = "dev0"
TopLevelMGPrefix="gehc-${env}"

dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
GROUP="rg-${TopLevelMGPrefix}-logging-001"
NAME="${TopLevelMGPrefix}-loggingDeployment-${dateYMD}"
TEMPLATEFILE="infra-as-code/bicep/modules/logging/logging.bicep"
PARAMETERS="@infra-as-code/bicep/modules/logging/parameters/logging.parameters.dev-gehc.json"

# Create Resource Group - optional when using an existing resource group
az group create \
  --name $GROUP \
  --location eastus2
```

2. Test which resources will be provisioned by this deployment:

  ```sh
az deployment group what-if --name ${NAME:0:63} --resource-group $GROUP --template-file $TEMPLATEFILE --parameters $PARAMETERS
  ```

3. Deploy the logging resources:

  ```sh
  az deployment group what-if --name ${NAME:0:63} --resource-group $GROUP --template-file $TEMPLATEFILE --parameters $PARAMETERS
  ```

## Management Group Diagnostic Settings

After the logging resources have been deployed, the deployment sequence specifies deployment of management group diagnostic settings.
> Note: this module has explicit dependencies on the log analytics workspace id created above, and on the custom landing zone management groups created in the initial management group hierarchy step.

To deploy the diagnostics settings:

1. Edit the [parameter file]("./infra-as-code/bicep/orchestration/mgDiagSettingsAll/parameters/mgDiagSettingsAll.parameters.dev-gehc.json")
2. Test which resources will be deployed:

```bash
# For Azure global regions
az deployment mg what-if \
  --template-file infra-as-code/bicep/orchestration/mgDiagSettingsAll/mgDiagSettingsAll.bicep \
  --parameters @infra-as-code/bicep/orchestration/mgDiagSettingsAll/parameters/mgDiagSettingsAll.parameters.dev-gehc.json \
  --location eastus2 \
  --management-group-id gehc-dev0
```

3. Deploy diagnostic settings:

```bash
az deployment mg create \
  --template-file infra-as-code/bicep/orchestration/mgDiagSettingsAll/mgDiagSettingsAll.bicep \
  --parameters @infra-as-code/bicep/orchestration/mgDiagSettingsAll/parameters/mgDiagSettingsAll.parameters.dev-gehc.json \
  --location eastus2 \
  --management-group-id gehc-dev0
```

# VWAN Connectivity

>Note: This module always creates a VWAN, and doesn't support creation of multiple hubs. We need to address this.

```bash
# For Azure global regions
# Set Platform connectivity subscription ID as the the current subscription
ConnectivitySubscriptionId="cf50834e-90ec-4e57-be7d-c755818f3096"
az account set --subscription $ConnectivitySubscriptionId

# Set the top level MG Prefix in accordance to your environment. This example assumes default 'alz'.
TopLevelMGPrefix="alz-dev"

dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
NAME="alz-vwanConnectivityDeploy-${dateYMD}"
GROUP="rg-$TopLevelMGPrefix-vwan-001"
TEMPLATEFILE="infra-as-code/bicep/modules/vwanConnectivity/vwanConnectivity.bicep"
PARAMETERS="@infra-as-code/bicep/modules/vwanConnectivity/parameters/vwanConnectivity.parameters.dev-gehc.json"

# Create Resource Group - optional when using an existing resource group
az group create \
  --name $GROUP \
  --location eastus2
```

## Role Assignments

There are a lot of options with the ALZ-Bicep role assignment module(s). And even more with the more generic Bicep modules. For now, this is the approach we'll take:

```bash
dateYMD=$(date +%Y%m%dT%H%M%S%NZ)
NAME="alz-RoleAssignmentsDeployment-alz-dev-${dateYMD}"
LOCATION="eastus2"
MGID="alz-dev"
TEMPLATEFILE="infra-as-code/bicep/modules/roleAssignments/roleAssignmentManagementGroup.bicep"
PARAMETERS="@infra-as-code/bicep/modules/roleAssignments/parameters/dev-gehc/alz-dev/roleAssignmentManagementGroup.securityGroup.parameters.dev-gehc.json"
```

Then test:

```bash
az deployment mg what-if --name ${NAME:0:63} --location $LOCATION --management-group-id $MGID --template-file $TEMPLATEFILE --parameters $PARAMETERS
```

Then deploy:

```bash
az deployment mg create --name ${NAME:0:63} --location $LOCATION --management-group-id $MGID --template-file $TEMPLATEFILE --parameters $PARAMETERS
```
