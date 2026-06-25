# providers.tf (or wherever your helm provider is declared)

data "azurerm_kubernetes_cluster" "aks" {
  name                = azurerm_kubernetes_cluster.main.name
  resource_group_name = azurerm_kubernetes_cluster.main.resource_group_name

  depends_on = [azurerm_kubernetes_cluster.main]
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }
}

=================================================================
# .github/workflows/deploy-aks.yml

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  AKS_CLUSTER_NAME: ${{ vars.AKS_CLUSTER_NAME }}         # or hardcode
  AKS_RESOURCE_GROUP: ${{ vars.AKS_RESOURCE_GROUP }}     # or hardcode

jobs:
  deploy:
    runs-on: self-hosted
    steps:

      - name: Checkout
        uses: actions/checkout@v4

      # ── STEP 1: Azure CLI Login ─────────────────────────────────────────────
      - name: Azure CLI Login
        run: |
          az login --service-principal \
            --username "$ARM_CLIENT_ID" \
            --password "$ARM_CLIENT_SECRET" \
            --tenant  "$ARM_TENANT_ID"
          az account set --subscription "$ARM_SUBSCRIPTION_ID"

      # ── STEP 2: Terraform Init + Apply (creates AKS) ───────────────────────
      - name: Terraform Init
        working-directory: ./infra
        run: terraform init

      - name: Terraform Apply (AKS cluster)
        working-directory: ./infra
        run: terraform apply -auto-approve -target=azurerm_kubernetes_cluster.main
        # Target ONLY the AKS resource first so it exists before Helm runs

      # ── STEP 3: Write kubeconfig AFTER AKS exists ──────────────────────────
      - name: Get AKS Credentials
        run: |
          az aks get-credentials \
            --resource-group "$AKS_RESOURCE_GROUP" \
            --name           "$AKS_CLUSTER_NAME" \
            --overwrite-existing
          # Verify connectivity before Terraform tries Helm
          kubectl get nodes

      # ── STEP 4: Full Terraform Apply (KEDA Helm release + everything else) ──
      - name: Terraform Apply (Full)
        working-directory: ./infra
        run: terraform apply -auto-approve

===========================================================================
# In your helm_release resource
resource "helm_release" "keda" {
  name             = "keda"
  repository       = "https://<your-org>.jfrog.io/artifactory/api/helm/<repo-name>"
  repository_username = var.jfrog_username
  repository_password = var.jfrog_password   # use an API token, not plaintext password
  chart            = "keda"
  namespace        = "keda"
  create_namespace = true
  version          = "2.x.x"

  depends_on = [azurerm_kubernetes_cluster.main]
}

==============================================================================
      # STEP 3 — Install kubectl + kubelogin
      - name: Install kubelogin
        shell: bash
        run: |
          az aks install-cli
          kubectl version --client
          kubelogin --version

# Convert token for Service Principal login
          kubelogin convert-kubeconfig -l spn \
            --client-id     "$ARM_CLIENT_ID" \
            --client-secret "$ARM_CLIENT_SECRET" \
            --tenant-id     "$ARM_TENANT_ID"
