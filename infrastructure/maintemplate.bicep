param storageAccountName string
param newsletterContainerName string
param keyVaultName string
param keyVaultAccessPolicyObjectId string

var location = resourceGroup().location
var tenantId = subscription().tenantId

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot' 
  }
}

resource newsletterContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-06-01' = {
  name: '${storageAccount.name}/default/${newsletterContainerName}'
}

resource keyVault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    accessPolicies: [
      {
        objectId: keyVaultAccessPolicyObjectId
        tenantId: tenantId
        permissions: {
          secrets: [
            'all'
          ]
        }
      }
    ]
  }
}

resource storageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'STORAGE-CONNECTION-STRING'
  parent: keyVault
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
  }
}

resource hashSaltSecret 'Microsoft.KeyVault/vaults/secrets@2021-06-01-preview' = {
  name: 'HASH-SALT'
  parent: keyVault
  properties: {
    value: uniqueString(resourceGroup().name, keyVault.name)
  }
}
