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

    Write-Host "Creating repository from template: $Owner/$TemplateRepo"

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/repos/$Owner/$TemplateRepo/generate"

    $headers = @{
        Authorization  = "Bearer $Token"
        Accept         = "application/vnd.github.v3+json"
        "Content-Type" = "application/json"
        "User-Agent"   = "pwsh-action"
    }

    $jsonBody = @{
        owner       = $Owner
        name        = $RepoName
        description = $RepoDescription
        private     = $true
    } | ConvertTo-Json

    try {
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Post -Body $jsonBody

        if ($response.StatusCode -eq 201) {
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
        } else {
            $message = ""
            try {
                $errorJson = $response.Content | ConvertFrom-Json
                $message = $errorJson.message
            } catch { $message = "Failed to read error message." }
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Failed to create repository: $message"
        }
    } catch {
        $errorMsg = ""
        if ($_.Exception.Response -and $_.Exception.Response.GetResponseStream()) {
            $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
            $content = $reader.ReadToEnd()
            $reader.Close()
            try {
                $errorJson = $content | ConvertFrom-Json
                $errorMsg = $errorJson.message
            } catch { $errorMsg = $content }
        }
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Failed to create repository: $errorMsg"
    }
}