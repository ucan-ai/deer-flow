# DeerFlow GCP Deployment Guide

## Prerequisites

1. **Google Cloud Project Setup**
```bash
# Install gcloud CLI
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

2. **Environment Configuration**
```bash
# Clone your repository
git clone https://github.com/ucan-ai/deer-flow.git
cd deer-flow

# Set up environment files
cp .env.example .env
cp conf.yaml.example conf.yaml

# Edit .env with your API keys:
# TAVILY_API_KEY=your_tavily_key
# BRAVE_SEARCH_API_KEY=your_brave_key
# OPENAI_API_KEY=your_openai_key
# etc.
```

## Deployment Method 1: Direct from GitHub

```bash
# Deploy directly from your GitHub repository
gcloud run deploy deer-flow-backend \
  --source https://github.com/ucan-ai/deer-flow \
  --platform managed \
  --region us-central1 \
  --port 8000 \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 3600 \
  --set-env-vars TAVILY_API_KEY=your_key,OPENAI_API_KEY=your_key
```

## Deployment Method 2: Build and Deploy Separately

```bash
# 1. Build the container image
gcloud builds submit --tag gcr.io/YOUR_PROJECT_ID/deer-flow .

# 2. Deploy to Cloud Run
gcloud run deploy deer-flow-backend \
  --image gcr.io/YOUR_PROJECT_ID/deer-flow \
  --platform managed \
  --region us-central1 \
  --port 8000 \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 3600 \
  --env-vars-file .env
```

## Deployment Method 3: Using Docker Compose with Cloud Run

Since DeerFlow has docker-compose support, you can deploy both backend and frontend:

### Backend Service
```bash
gcloud run deploy deer-flow-api \
  --source . \
  --platform managed \
  --region us-central1 \
  --port 8000 \
  --memory 2Gi \
  --cpu 2 \
  --env-vars-file .env
```

### Frontend Service
```bash
# Create a separate Dockerfile for frontend in the web/ directory
cd web
gcloud run deploy deer-flow-web \
  --source . \
  --platform managed \
  --region us-central1 \
  --port 3000 \
  --memory 1Gi \
  --set-env-vars NEXT_PUBLIC_API_URL=https://deer-flow-api-xxx.run.app
```

## Environment Variables Configuration

Create a `.env` file with your configuration:

```env
# Search APIs
SEARCH_API=tavily
TAVILY_API_KEY=your_tavily_key
BRAVE_SEARCH_API_KEY=your_brave_key

# LLM Configuration
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key

# Other services
JINA_API_KEY=your_jina_key
VOLCENGINE_API_KEY=your_volcengine_key

# Application settings
PORT=8000
HOST=0.0.0.0
```

## Continuous Deployment Setup

Create `cloudbuild.yaml` in your repository root:

```yaml
steps:
  # Build the container
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'gcr.io/$PROJECT_ID/deer-flow', '.']
  
  # Push to Container Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'gcr.io/$PROJECT_ID/deer-flow']
  
  # Deploy to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: gcloud
    args: 
    - 'run'
    - 'deploy'
    - 'deer-flow-backend'
    - '--image'
    - 'gcr.io/$PROJECT_ID/deer-flow'
    - '--region'
    - 'us-central1'
    - '--platform'
    - 'managed'
    - '--allow-unauthenticated'

# Set up GitHub trigger
substitutions:
  _SERVICE_NAME: deer-flow-backend
  _REGION: us-central1
```

Set up the trigger:
```bash
gcloud builds triggers create github \
  --repo-name=deer-flow \
  --repo-owner=ucan-ai \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml
```

## Alternative: Google Kubernetes Engine (GKE)

For production workloads requiring more control:

```bash
# Create GKE cluster
gcloud container clusters create deer-flow-cluster \
  --zone us-central1-a \
  --num-nodes 3

# Deploy using kubectl
kubectl apply -f k8s/
```

## Important Notes for DeerFlow

1. **Memory Requirements**: DeerFlow processes research tasks and may need 2GB+ RAM
2. **Timeout Settings**: Research operations can take time, set timeout to 3600 seconds
3. **Environment Variables**: Ensure all API keys are properly configured
4. **Port Configuration**: Backend uses port 8000, frontend uses port 3000
5. **File Storage**: Consider using Cloud Storage for generated reports/files

## Cost Optimization

- Use Cloud Run for serverless scaling
- Set minimum instances to 0 for cost savings
- Use Cloud Build for efficient container builds
- Consider using Cloud Storage for file uploads/downloads

## Monitoring and Logging

```bash
# View logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=deer-flow-backend"

# Set up monitoring
gcloud alpha monitoring dashboards create --config-from-file=monitoring.yaml
```

## Security Considerations

- Store API keys in Google Secret Manager
- Use IAM roles for service-to-service communication
- Enable VPC if needed for private networking
- Use Cloud Armor for DDoS protection if public-facing