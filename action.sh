#!/bin/bash

create_repository() {
  local repo_name="$1"
  local repo_description="$2"
  local template_repo="$3"
  local owner="$4"
  local token="$5"

  # Validate required inputs
  if [ -z "$repo_name" ] || [ -z "$repo_description" ] || [ -z "$template_repo" ] || [ -z "$owner" ] || [ -z "$token" ]; then
    echo "Error: Missing required parameters"
    echo "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided." >> "$GITHUB_OUTPUT"                        
    echo "result=failure" >> "$GITHUB_OUTPUT"
    return
  fi

  echo "Creating repository from template: $owner/$template_repo"

  # Use MOCK_API if set, otherwise default to GitHub API
  local api_base_url="${MOCK_API:-https://api.github.com}"
  local api_url="$api_base_url/repos/$owner/$template_repo/generate"

  RESPONSE=$(curl -s -o response.json -w "%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    "$api_url" \
    -d "{\"owner\": \"$owner\", \"name\": \"$repo_name\", \"description\": \"$repo_description\", \"private\": true}"
    )

  if [ "$RESPONSE" -ne 201 ]; then
    echo "result=failure" >> "$GITHUB_OUTPUT"
    echo "error-message=Failed to create repository: $(jq -r .message response.json)" >> "$GITHUB_OUTPUT"
    rm -f response.json
    return
  fi

  echo "result=success" >> "$GITHUB_OUTPUT"
  rm -f response.json
}
