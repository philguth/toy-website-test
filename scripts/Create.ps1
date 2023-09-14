$githubOrganizationName = 'philguth'
$githubRepositoryName = 'toy-website-environments'

$testApplicationRegistration = New-AzADApplication -DisplayName 'toy-website-environments-test'
New-AzADAppFederatedCredential `
    -Name 'toy-website-environments-test' `
    -ApplicationObjectId $testApplicationRegistration.Id `
    -Issuer 'https://token.actions.githubusercontent.com' `
    -Audience 'api://AzureADTokenExchange' `
    -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):environment:Test"
New-AzADAppFederatedCredential `
    -Name 'toy-website-environments-test-branch' `
    -ApplicationObjectId $testApplicationRegistration.Id `
    -Issuer 'https://token.actions.githubusercontent.com' `
    -Audience 'api://AzureADTokenExchange' `
    -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):ref:refs/heads/main"

$productionApplicationRegistration = New-AzADApplication -DisplayName 'toy-website-environments-production'
New-AzADAppFederatedCredential `
    -Name 'toy-website-environments-production' `
    -ApplicationObjectId $productionApplicationRegistration.Id `
    -Issuer 'https://token.actions.githubusercontent.com' `
    -Audience 'api://AzureADTokenExchange' `
    -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):environment:Production"
New-AzADAppFederatedCredential `
    -Name 'toy-website-environments-production-branch' `
    -ApplicationObjectId $productionApplicationRegistration.Id `
    -Issuer 'https://token.actions.githubusercontent.com' `
    -Audience 'api://AzureADTokenExchange' `
    -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):ref:refs/heads/main"



$testResourceGroup = New-AzResourceGroup -Name ToyWebsiteTest -Location northcentralus

New-AzADServicePrincipal -AppId $($testApplicationRegistration.AppId)
New-AzRoleAssignment `
    -ApplicationId $($testApplicationRegistration.AppId) `
    -RoleDefinitionName Contributor `
    -Scope $($testResourceGroup.ResourceId)


$productionResourceGroup = New-AzResourceGroup -Name ToyWebsiteProduction -Location northcentralus

New-AzADServicePrincipal -AppId $($productionApplicationRegistration.AppId)
New-AzRoleAssignment `
    -ApplicationId $($productionApplicationRegistration.AppId) `
    -RoleDefinitionName Contributor `
    -Scope $($productionResourceGroup.ResourceId)



$azureContext = Get-AzContext
Write-Host "AZURE_CLIENT_ID_TEST: $($testApplicationRegistration.AppId)"
Write-Host "AZURE_CLIENT_ID_PRODUCTION: $($productionApplicationRegistration.AppId)"
Write-Host "AZURE_TENANT_ID: $($azureContext.Tenant.Id)"
Write-Host "AZURE_SUBSCRIPTION_ID: $($azureContext.Subscription.Id)"