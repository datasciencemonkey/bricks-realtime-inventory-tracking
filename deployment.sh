#!/bin/bash

# deployment.sh - Deploy Supply Chain Tracker to Cloud Run
# This script prepares backend and frontend files for deployment

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Supply Chain Tracker Deployment Script ===${NC}\n"

# Define directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_SRC="$SCRIPT_DIR/backend"
FRONTEND_BUILD="$SCRIPT_DIR/supply_chain_tracker/build/web"
DEPLOY_DIR="$SCRIPT_DIR/deployment"
DEPLOY_BACKEND="$DEPLOY_DIR/backend"
DEPLOY_FRONTEND="$DEPLOY_DIR/frontend"

# Check if backend source exists
if [ ! -d "$BACKEND_SRC" ]; then
    echo -e "${RED}Error: Backend directory not found at $BACKEND_SRC${NC}"
    exit 1
fi

# Check if frontend build exists
if [ ! -d "$FRONTEND_BUILD" ]; then
    echo -e "${YELLOW}Warning: Frontend build not found at $FRONTEND_BUILD${NC}"
    echo -e "${YELLOW}Run 'flutter build web' in supply_chain_tracker/ first${NC}"
    read -p "Continue without frontend? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    SKIP_FRONTEND=true
fi

# Create deployment directories
echo -e "${GREEN}Creating deployment directories...${NC}"
mkdir -p "$DEPLOY_BACKEND"
mkdir -p "$DEPLOY_FRONTEND"

# Copy backend files
echo -e "${GREEN}Copying backend files...${NC}"
cp "$BACKEND_SRC/main.py" "$DEPLOY_BACKEND/"
cp "$BACKEND_SRC/requirements.txt" "$DEPLOY_BACKEND/"
cp "$BACKEND_SRC/.env.example" "$DEPLOY_BACKEND/"

# Check if .env exists and copy it
if [ -f "$BACKEND_SRC/.env" ]; then
    echo -e "${YELLOW}Found .env file - copying to deployment${NC}"
    cp "$BACKEND_SRC/.env" "$DEPLOY_BACKEND/"
else
    echo -e "${YELLOW}No .env file found - using .env.example${NC}"
fi

# Copy frontend build files if available
if [ "$SKIP_FRONTEND" != true ]; then
    echo -e "${GREEN}Copying frontend build files...${NC}"
    cp -r "$FRONTEND_BUILD/"* "$DEPLOY_FRONTEND/"
    echo -e "${GREEN}Frontend files copied successfully${NC}"
fi

# Create/Update app.yaml
echo -e "\n${GREEN}Setting up app.yaml configuration...${NC}"
echo -e "${YELLOW}Please provide the following information:${NC}\n"

# Prompt for configuration
read -p "Databricks Host [https://fe-vm-vdm-serverless-jpckvw.cloud.databricks.com]: " DB_HOST
DB_HOST=${DB_HOST:-"https://fe-vm-vdm-serverless-jpckvw.cloud.databricks.com"}

read -p "Databricks Token: " DB_TOKEN
if [ -z "$DB_TOKEN" ]; then
    echo -e "${YELLOW}Using token from existing app.yaml or .env${NC}"
    # Try to read from .env
    if [ -f "$DEPLOY_BACKEND/.env" ]; then
        DB_TOKEN=$(grep DATABRICKS_TOKEN "$DEPLOY_BACKEND/.env" | cut -d '=' -f2 | tr -d '"' | tr -d "'")
    fi
fi

read -p "Databricks HTTP Path [/sql/1.0/warehouses/d190b568810b2c60]: " DB_PATH
DB_PATH=${DB_PATH:-"/sql/1.0/warehouses/d190b568810b2c60"}

read -p "Databricks Catalog [supplychain]: " DB_CATALOG
DB_CATALOG=${DB_CATALOG:-"supplychain"}

read -p "Databricks Schema [supplychain_visibility]: " DB_SCHEMA
DB_SCHEMA=${DB_SCHEMA:-"supplychain_visibility"}

# Create app.yaml
cat > "$DEPLOY_DIR/app.yaml" << EOF
runtime: python312

entrypoint: uvicorn backend.main:app --host 0.0.0.0 --port \$PORT

env_variables:
  DATABRICKS_HOST: "$DB_HOST"
  DATABRICKS_TOKEN: "$DB_TOKEN"
  DATABRICKS_HTTP_PATH: "$DB_PATH"
  DATABRICKS_CATALOG: "$DB_CATALOG"
  DATABRICKS_SCHEMA: "$DB_SCHEMA"

handlers:
  # Serve static frontend files
  - url: /
    static_files: frontend/index.html
    upload: frontend/index.html

  - url: /(.*)
    static_files: frontend/\1
    upload: frontend/.*

  # API endpoints
  - url: /api/.*
    script: auto
    secure: always

automatic_scaling:
  min_instances: 0
  max_instances: 10
  target_cpu_utilization: 0.65
EOF

echo -e "\n${GREEN}app.yaml created successfully!${NC}"
echo -e "\n${GREEN}=== Deployment preparation complete! ===${NC}\n"

echo -e "Directory structure:"
echo -e "  ${DEPLOY_DIR}/"
echo -e "    ├── app.yaml"
echo -e "    ├── backend/"
echo -e "    │   ├── main.py"
echo -e "    │   ├── requirements.txt"
echo -e "    │   └── .env"
if [ "$SKIP_FRONTEND" != true ]; then
    echo -e "    └── frontend/"
    echo -e "        └── (web build files)"
fi

echo -e "\n${YELLOW}Next steps:${NC}"
echo -e "  1. Review ${DEPLOY_DIR}/app.yaml"
echo -e "  2. cd deployment"
echo -e "  3. gcloud app deploy"
echo
