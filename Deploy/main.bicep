param sku string = 'Standard'
param skuCode string = 'S1'
param registrySku string = 'Standard'
param workerSize int = 1
param apiBaseUrl string = 'https://backend.tailwindtraders.com/'
var dockerimage = '${acr_name_var}.azurecr.io/tailwindtraders-app:latest'
var website_name_var = 'tailwindtraders${uniqueString(resourceGroup().id)}'
var plan_name_var = 'ttappserviceplan${uniqueString(resourceGroup().id)}'
var acr_name_var = 'ttacr${uniqueString(resourceGroup().id)}'
var deployment_slot_name = 'staging'
var acr_password_var = 'acrPassword'
var keyvault_name_var = 'ttkv${uniqueString(resourceGroup().id)}'
var objectId = '7567ff67-3589-4cd6-a42c-9a6e8cb60e0f'
var objectId = 'f5cccb74-8917-4be6-9bb4-02f254bb2729'
 { 

  "clientId": "f2866692-6a93-48d2-bf2d-b2b13d68d3b1", 

  "displayName": "azure-cli-2021-10-07-14-17-36", 

  "name": "f2866692-6a93-48d2-bf2d-b2b13d68d3b1", 

  "clientSecret": "ZFmE37VkO7PaBLD~sh6qlsSzXyPxH37awn", 

  "tenantId": "72f988bf-86f1-41af-91ab-2d7cd011db47",

"subscriptionId": "f7f87330-1754-4aa5-9abd-0bd1626aa71d" 

}  
resource acr_name 'Microsoft.ContainerRegistry/registries@2017-10-01' = {
  name: acr_name_var
  location: resourceGroup().location
  sku: {
    name: registrySku
  }
  properties: {
    adminUserEnabled: true
  }
}

resource website_name 'Microsoft.Web/sites@2018-02-01' = {
  name: website_name_var
  location: resourceGroup().location
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acr_name_var}.azurecr.io'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: listCredentials(acr_name.id, acr_name.apiVersion).passwords[0].value
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: acr_name_var
        }
        {
          name: 'ApiUrl'
          value: '${apiBaseUrl}/webbff/v1'
        }
        {
          name: 'ApiUrlShoppingCart'
          value: '${apiBaseUrl}/cart-api'
        }
      ]
      appCommandLine: ''
      linuxFxVersion: 'DOCKER|${dockerimage}'
    }
    serverFarmId: plan_name.id
  }
}

resource deployment_slot 'Microsoft.Web/sites/slots@2021-01-15' = {
  name: deployment_slot_name
  location: resourceGroup().location
  properties:{
    siteConfig: {
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acr_name_var}.azurecr.io'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: listCredentials(acr_name.id, acr_name.apiVersion).passwords[0].value
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: acr_name_var
        }
        {
          name: 'ApiUrl'
          value: '${apiBaseUrl}/webbff/v1'
        }
        {
          name: 'ApiUrlShoppingCart'
          value: '${apiBaseUrl}/cart-api'
        }
      ]
      appCommandLine: ''
      linuxFxVersion: 'DOCKER|${dockerimage}'
      
    }
    enabled: true
    serverFarmId: plan_name.id
  }
  parent: website_name
  dependsOn: [
    acr_name
  ]
}

resource plan_name 'Microsoft.Web/serverfarms@2016-09-01' = {
  name: plan_name_var
  location: resourceGroup().location
  sku: {
    tier: sku
    name: skuCode
  }
  kind: 'linux'
  properties: {
    name: plan_name_var
    targetWorkerSizeId: workerSize
    targetWorkerCount: 1
    reserved: true
  }
}

resource keyvault 'Microsoft.KeyVault/vaults@2016-10-01' = {
  name: keyvault_name_var
  location: resourceGroup().location
  properties: {
  accessPolicies: [
    {
      objectId: objectId
      tenantId: subscription().tenantId
      permissions: {
        keys: []
        secrets: [
          'set'
          'get'
          'list'
        ]
      }
    }
  ]
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    
  }
}

resource kv_secret 'Microsoft.KeyVault/vaults/secrets@2016-10-01' = {
  name: '${keyvault_name_var}/${acr_password_var}'
  properties: {
    value: listCredentials(acr_name.id, acr_name.apiVersion).passwords[0].value
  }
  dependsOn: [
    acr_name
  ]
}

output web string = website_name_var
output acr string = acr_name_var
output kv string = keyvault_name_var
