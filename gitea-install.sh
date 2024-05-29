#!/bin/bash

# Getting the Console URL
CONSOLE_URL=$(oc whoami --show-console)
HOSTNAME=$(echo $CONSOLE_URL | sed 's|https://console-openshift-console|gitea|')

# Configuration
NAMESPACE=${NAMESPACE:="gitea"}
USERNAME=${USERNAME:="dev"}
PASSWORD=${PASSWORD:="123456"}
EMAIL=${EMAIL:="dev@openshift.com"}
SAMPLE_REPOS_DIR=${SAMPLE_REPOS_DIR:="$HOME/Documents/gitea-samples"}

# Setting the Namespace
kubectl create ns $NAMESPACE

# Helm install command
echo "Installing Gitea Helm Chart..."
helm upgrade --install --repo=https://redhat-cop.github.io/helm-charts gitea gitea --set db.password=S00perSekretP@ssw0rd --set hostname=$HOSTNAME -n $NAMESPACE

# Wait for the Gitea pod to be ready
echo "Waiting for Gitea pods to be ready..."
kubectl wait --for=condition=available dc -l app=gitea -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l deploymentconfig=gitea -n $NAMESPACE --timeout=300s
kubectl wait --for=condition=ready pod -l deploymentconfig=gitea-db -n $NAMESPACE --timeout=300s

# Get the name of the Gitea pod
GITEA_POD=$(kubectl get pods -n $NAMESPACE -l deploymentconfig=gitea -o jsonpath="{.items[0].metadata.name}")

# Create the admin user
echo "Creating admin user..."
kubectl exec -it $GITEA_POD -n $NAMESPACE -- ./gitea --config /home/gitea/conf/app.ini admin user create --username $USERNAME --password $PASSWORD --email $EMAIL --admin true --must-change-password false

# Create an access token for the admin user
echo "Generating access token..."
TOKEN=$(kubectl exec -it $GITEA_POD -n $NAMESPACE -- ./gitea --config /home/gitea/conf/app.ini admin user generate-access-token --username $USERNAME --token-name "admin token" --scopes all | grep "Access token was successfully created" | awk '{print $6}'| tr -d '\r')

# Print the access token
echo "Access token for user '$USERNAME': $TOKEN"

#Login to the Gitea Server
echo "Logging to the Gitea Server..."
TEA_LOGIN=$(date +%d%m%Y%H%M)
tea login add --insecure --name $TEA_LOGIN --token $TOKEN --url https://$HOSTNAME

# Define the credentials to add
NETRC_ENTRY="machine $HOSTNAME login $USERNAME password $PASSWORD"

# Check if the .netrc file exists
if [ ! -f ~/.netrc ]; then
  # If .netrc does not exist, create it and add the credentials
  echo "$NETRC_ENTRY" > ~/.netrc
  chmod 600 ~/.netrc
else
  # If .netrc exists, check if the credentials are already there
  if ! grep -q "$NETRC_ENTRY" ~/.netrc; then
    # If the credentials are not there, append them
    echo "$NETRC_ENTRY" >> ~/.netrc
  fi
fi

# Temporary folder for samples
mkdir -p "$SAMPLE_REPOS_DIR"
cd "$SAMPLE_REPOS_DIR"

# Associative array for repository names and clone URLs
declare -A REPOS
REPOS=(
  ["nodejs"]="https://github.com/johnpapa/node-hello.git"
  ["dockerfile-node"]="https://github.com/Lucifergene/knative-do-demo"
  ["devfile"]="https://github.com/nodeshift-starters/devfile-sample"
  ["pac"]="https://github.com/Lucifergene/oc-pipe"
  ["serv-func"]="https://github.com/Lucifergene/oc-func"
)

# Loop through the associative array and create repositories
for REPO_NAME in "${!REPOS[@]}"; do
  CLONE_REPO_URL=${REPOS[$REPO_NAME]}

  echo "Creating $REPO_NAME Repository..."

  # Create repository
  tea repos create --name $REPO_NAME --login $TEA_LOGIN

  # Clone the new repository
  git -c http.sslVerify=false clone https://$HOSTNAME/dev/$REPO_NAME.git
  cd $REPO_NAME

  # Clone the source repository into the new repository directory
  git clone $CLONE_REPO_URL $REPO_NAME
  mv ./$REPO_NAME/* .
  # Move the special .tekton folder if it exists
  if [ -d ./$REPO_NAME/.tekton ]; then
    mv ./$REPO_NAME/.tekton .
  fi
  rm -rf $REPO_NAME

  # Commit and push the changes
  git add .
  git commit -m "first commit"
  git -c http.sslVerify=false push origin main

  # Move back to the parent directory
  cd ..
done
