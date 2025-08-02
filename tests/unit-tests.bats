#!/usr/bin/env bats

# Load the Bash script (source the action's script)
load ../action.sh

# Mock the curl command to simulate API responses
mock_curl() {
  local http_code=$1
  local response_file=$2
  echo "$http_code"
  cat "$response_file" > response.json
}

# Setup function to run before each test
setup() {
  export GITHUB_OUTPUT=$(mktemp)
}

# Teardown function to clean up after each test
teardown() {
  rm -f response.json "$GITHUB_OUTPUT" mock_response.json
}

@test "create_repository succeeds with HTTP 201" {
  echo '{"message": "Repository created"}' > mock_response.json
  curl() { mock_curl "201" mock_response.json; }
  export -f curl

  run create_repository "new-repo" "Test repo" "template-repo" "test-owner" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(cat "$GITHUB_OUTPUT")" == "result=success" ]
}

@test "create_repository fails with HTTP 422" {
  echo '{"message": "Repository creation failed"}' > mock_response.json
  curl() { mock_curl "422" mock_response.json; }
  export -f curl

  run create_repository "new-repo" "Test repo" "template-repo" "test-owner" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Failed to create repository: Repository creation failed" ]
}

@test "create_repository fails with empty repo_name" {
  run create_repository "" "Test repo" "template-repo" "test-owner" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided." ]
}

@test "create_repository fails with empty repo_description" {
  run create_repository "new-repo" "" "template-repo" "test-owner" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided." ]
}

@test "create_repository fails with empty template_repo" {
  run create_repository "new-repo" "Test repo" "" "test-owner" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided." ]
}

@test "create_repository fails with empty owner" {
  run create_repository "new-repo" "Test repo" "template-repo" "" "fake-token"

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided." ]
}

@test "create_repository fails with empty token" {
  run create_repository "new-repo" "Test repo" "template-repo" "test-owner" ""

  [ "$status" -eq 0 ]
  [ "$(grep 'result' "$GITHUB_OUTPUT")" == "result=failure" ]
  [ "$(grep 'error-message' "$GITHUB_OUTPUT")" == "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided." ]
}
