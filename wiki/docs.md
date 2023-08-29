# Using Workload Identities for Bicep Deployments in GitHub Actions

## Workload Identities - Defined

These identities are assigned to Azure Resources and managed through Azure AD (Entra). They allow resources to authenticate and interact with other resources without requiring the use of explicit credentials. Security is enhanced, because there is no need to store and manage credentials within application code or configuration files. Workload identities are commonly referred to as 'Managed Identities' and there are 2 types: System-assigned and User Assigned.

## Application Registrations - Defined

An application registration is automatically created in Azure AD (Entra) when a workload identity is created for an Azure resource. This registration is where you define and configure how the application will authenticate and interact with Azure AD. These registrations are used when an application you are building needs to authenticate users or access APIs secured by Azure AD. The registration represents the identity of the resource in Azure AD and allows the resource to authenticate and request access tokens to interact with other Azure services or resources.

## Workload Identities and Application Registrations

While the application registration is created as part of setting up a managed identity, the main focus of the managed identity is to provide a secure way for the Azure resource to obtain credentials without directly handling secrets. The application registration aspect is more of an implementation detail required for authentication and authorization purposes.

In other words, the managed identity and the application registration are closely related, but they serve distinct purposes: the managed identity provides secure authentication for the resource, and the associated application registration facilitates the necessary interactions with Azure AD to achieve this authentication.
