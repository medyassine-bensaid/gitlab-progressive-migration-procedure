#!/bin/bash

# List of GitLab versions to upgrade
versions=(
  "14.10.0-ee.0"
  "15.0.5-ee.0"
  "15.1.6-ee.0"
  "15.4.6-ee.0"
  "15.11.13-ee.0"
  "16.0.8-ee.0"
  "16.1.6-ee.0"
  "16.2.9-ee.0"
  "16.3.7-ee.0"
  "16.7.7-ee.0"
  "16.8.7-ee.0"
)

# Path to Docker Compose file
compose_file="docker-compose.yml"

# Function to update Docker Compose file with the new version
update_compose_file() {
  local version=$1
  sed -i "s|\${GITLAB_VERSION}|${version}|" ${compose_file}
}

# Function to revert Docker Compose file to the template version
revert_compose_file() {
  local version=$1
  sed -i "s|${version}|\${GITLAB_VERSION}|" ${compose_file}
}

# Function to check GitLab service status
check_gitlab_status() {
  docker exec gitlab gitlab-ctl status > /dev/null 2>&1
  return $?
}

# Iterate through each version and perform the upgrade
for version in "${versions[@]}"; do
  echo "Upgrading to GitLab version ${version}..."
  
  # Pull the new Docker image
  docker pull gitlab/gitlab-ee:${version}
  
  # Update the Docker Compose file
  update_compose_file ${version}
  
  # Restart the Docker Compose services
  docker compose down
  docker compose up -d
  
  # Wait for the upgrade to complete
  echo "Waiting for GitLab to start..."
  while ! check_gitlab_status; do
    echo "GitLab is not ready yet. Waiting..."
    sleep 10
  done
  
  echo "GitLab is up and running with version ${version}."
  
  # Revert the Docker Compose file to use the placeholder
  revert_compose_file ${version}
done

echo "GitLab upgrade process completed."
