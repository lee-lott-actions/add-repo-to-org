# Add Repository From Template Action

This GitHub Action creates a new repository from a specified template repository using the GitHub API. It returns a result indicating whether the repository was created successfully (`success` for HTTP 201, `failure` otherwise) and an error message with details if the creation fails.

## Features
- Creates a new private repository from a template repository via the GitHub API.
- Outputs a result (`success` or `failure`) and an error message for easy integration into workflows.
- Requires a GitHub token with `repo` scope for repository creation.

## Inputs
| Name              | Description                                      | Required | Default |
|-------------------|--------------------------------------------------|----------|---------|
| `repo-name`       | The name of the new repository to create.        | Yes      | N/A     |
| `repo-description`| The description for the new repository.          | Yes      | ''      |
| `template-repo`   | The name of the template repository to use.      | Yes      | N/A     |
| `owner`           | The owner of the template and new repository (user or organization). | Yes | N/A |
| `token`           | GitHub token with repository write access.       | Yes      | N/A     |

## Outputs
| Name           | Description                                           |
|----------------|-------------------------------------------------------|
| `result`       | Result of the repository creation (`success` for HTTP 201, `failure` otherwise). |
| `error-message`| Error message if the repository creation fails.       |

## Usage
1. **Add the Action to Your Workflow**:
   Create or update a workflow file (e.g., `.github/workflows/create-repo.yml`) in your repository.

2. **Reference the Action**:
   Use the action by referencing the repository and version (e.g., `v1`), or the local path if stored in the same repository.

3. **Example Workflow**:
   ```yaml
   name: Create Repository From Template
   on:
     push:
       branches:
         - main
   jobs:
     create-repo:
       runs-on: ubuntu-latest
       steps:
         - name: Create Repository
           id: create-repo
           uses: la-actions/create-repo-from-template@v1.0.2
           with:
             repo-name: 'new-repo'
             repo-description: 'A new repository created from a template'
             template-repo: 'my-template-repo'
             owner: ${{ github.repository_owner }}
             token: ${{ secrets.GITHUB_TOKEN }}
         - name: Check Result
           run: |
             if [[ "${{ steps.create-repo.outputs.result }}" == "success" ]]; then
               echo "Repository created successfully."
             else
               echo "${{ steps.create-repo.outputs.error-message }}"
               exit 1
             fi
