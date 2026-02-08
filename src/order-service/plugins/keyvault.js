'use strict'

/**
 * Key Vault Secrets Helper
 * 
 * ARCHITECTURE THOUGHT PROCESS:
 * 
 * This module provides a centralized way to fetch secrets from Azure Key Vault.
 * When running in AKS with Workload Identity:
 * 
 * 1. Pod has a ServiceAccount with azure.workload.identity/client-id annotation
 * 2. AKS injects an OIDC token into the pod (via projected volume)
 * 3. DefaultAzureCredential() discovers this token automatically
 * 4. We exchange the token for an Azure access token
 * 5. We use that token to call Key Vault API
 * 
 * This is the Azure equivalent of using AWS Secrets Manager with IRSA.
 * 
 * FALLBACK: If KEY_VAULT_URI is not set, we return null and the app
 *           falls back to environment variables (for local dev).
 */

const { DefaultAzureCredential } = require("@azure/identity")
const { SecretClient } = require("@azure/keyvault-secrets")

// Cache the client and secrets to avoid repeated API calls
let secretClient = null
const secretCache = new Map()

/**
 * Initialize the Key Vault client if KEY_VAULT_URI is set
 */
function initializeClient() {
  if (secretClient) return secretClient
  
  const vaultUri = process.env.KEY_VAULT_URI
  if (!vaultUri) {
    console.log('[KeyVault] KEY_VAULT_URI not set, using environment variables for secrets')
    return null
  }
  
  console.log(`[KeyVault] Initializing client for ${vaultUri}`)
  
  // DefaultAzureCredential tries multiple auth methods in order:
  // 1. Environment variables
  // 2. Workload Identity (what we use in AKS)
  // 3. Managed Identity
  // 4. Azure CLI
  // 5. etc.
  const credential = new DefaultAzureCredential()
  secretClient = new SecretClient(vaultUri, credential)
  
  return secretClient
}

/**
 * Fetch a secret from Key Vault
 * @param {string} secretName - Name of the secret in Key Vault
 * @returns {Promise<string|null>} - Secret value or null if not found/not configured
 */
async function getSecret(secretName) {
  // Check cache first
  if (secretCache.has(secretName)) {
    return secretCache.get(secretName)
  }
  
  const client = initializeClient()
  if (!client) {
    return null
  }
  
  try {
    console.log(`[KeyVault] Fetching secret: ${secretName}`)
    const secret = await client.getSecret(secretName)
    
    // Cache the secret value
    secretCache.set(secretName, secret.value)
    console.log(`[KeyVault] Successfully fetched secret: ${secretName}`)
    
    return secret.value
  } catch (error) {
    console.error(`[KeyVault] Failed to fetch secret ${secretName}:`, error.message)
    return null
  }
}

/**
 * Get RabbitMQ connection URI from Key Vault or environment
 * @returns {Promise<string|null>}
 */
async function getRabbitMQUri() {
  // Try Key Vault first
  const kvUri = await getSecret('rabbitmq-uri')
  if (kvUri) {
    return kvUri
  }
  
  // Fallback to environment variable
  if (process.env.ORDER_QUEUE_URI) {
    console.log('[KeyVault] Using ORDER_QUEUE_URI from environment')
    return process.env.ORDER_QUEUE_URI
  }
  
  return null
}

module.exports = {
  getSecret,
  getRabbitMQUri,
  initializeClient
}
