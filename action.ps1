function New-GitHubRepositoryFromTemplate {
    param(
        [string]$RepoName,
        [string]$RepoDescription,
        [string]$TemplateRepo,
        [string]$Owner,
        [string]$Token
    )

    # Validate required parameters
    if ([string]::IsNullOrEmpty($RepoName) -or
        [string]::IsNullOrEmpty($RepoDescription) -or
        [string]::IsNullOrEmpty($TemplateRepo) -or
        [string]::IsNullOrEmpty($Owner) -or
        [string]::IsNullOrEmpty($Token)) {
        Write-Host "Error: Missing required parameters"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }   

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/repos/$Owner/$TemplateRepo/generate"

    $headers = @{
        Authorization = "Bearer $Token"
        Accept = "application/vnd.github.v3+json"
		"X-GitHub-Api-Version" = "2026-03-10"
        "Content-Type" = "application/json"
    }

    $body = @{
        owner       = $Owner
        name        = $RepoName
        description = $RepoDescription
        private     = $true
    } | ConvertTo-Json

    try {
		Write-Host "Creating repository from template: $Owner/$TemplateRepo"
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $body -SkipHttpErrorCheck

        if ($response.StatusCode -eq 201) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
        } else {
			$errorMsg = "Error: Failed to create repository $Owner/$RepoName. HTTP Status: $($response.StatusCode)"
			Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"			
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
			Write-Host $errorMsg
        }
    } catch {
		$errorMsg = "Error: Failed to create repository $Owner/$RepoName. Exception: $($_.Exception.Message)"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
    }
}
