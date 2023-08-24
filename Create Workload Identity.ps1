
#Part 1
# Connect to your Azure account using Azure PowerShell module
Connect-AzAccount

# Define the GitHub organization name and repository name
$githubOrganizationName = 'philguth'
$githubRepositoryName = 'toy-website-test'

# Create a new Azure AD application registration with the specified display name
$applicationRegistration = New-AzADApplication -DisplayName 'toy-website-test'

# Create a new federated credential for the Azure AD application
# 2 - Name for the federated credential
# 3 - The ID of the previously created application registration
# 4 - Issuer URL for the token
# 5 - Audience URL for the token
# 6 - Subject for the token, indicating the repository, branch, and ref (in this case, 'main')
New-AzADAppFederatedCredential `
   -Name 'toy-website-test' `
   -ApplicationObjectId $applicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):environment:Website"
   
New-AzADAppFederatedCredential `
-Name 'toy-website-test-branch' `
-ApplicationObjectId $applicationRegistration.Id `
-Issuer 'https://token.actions.githubusercontent.com' `
-Audience 'api://AzureADTokenExchange' `
-Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):ref:refs/heads/main"
   


#Part 2
# Create a new Azure resource group with the specified name and location
$resourceGroup = New-AzResourceGroup -Name ToyWebsiteTest -Location northcentralus

# Create a new service principal in Azure AD using the provided AppId from the application registration
New-AzADServicePrincipal -AppId $applicationRegistration.AppId

# Assign the 'Contributor' role to the previously created service principal
# 2 - The AppId of the service principal
# 3 - The role to be assigned ('Contributor' in this case)
# 4 - The scope where the role is being assigned (resource group in this case)
New-AzRoleAssignment `
   -ApplicationId $($applicationRegistration.AppId) `
   -RoleDefinitionName Contributor `
   -Scope $resourceGroup.ResourceId   



#Part 3
# Get the current Azure context, which contains information about the logged-in account and subscription
$azureContext = Get-AzContext

# Display the Azure Client ID (Application ID) from the previously created application registration
Write-Host "AZURE_CLIENT_ID: $($applicationRegistration.AppId)"

# Display the Azure Tenant ID from the current Azure context
Write-Host "AZURE_TENANT_ID: $($azureContext.Tenant.Id)"

# Display the Azure Subscription ID from the current Azure context
Write-Host "AZURE_SUBSCRIPTION_ID: $($azureContext.Subscription.Id)"
