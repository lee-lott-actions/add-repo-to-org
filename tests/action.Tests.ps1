Describe "New-GitHubRepositoryFromTemplate" {
    BeforeAll {
        $script:RepoName        = "new-repo"
        $script:RepoDescription = "Test repo"
        $script:TemplateRepo    = "template-repo"
        $script:Owner           = "test-owner"
        $script:Token           = "fake-token"
        $script:MockApiUrl      = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }
    BeforeEach {
        $env:GITHUB_OUTPUT = "$PSScriptRoot/github_output.temp"
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        $env:MOCK_API = $script:MockApiUrl
    }
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Variable -Name MOCK_API -Scope Global -ErrorAction SilentlyContinue
    }

    It "create_repository succeeds with HTTP 201" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 201; Content = '{"message": "Repository created"}' }
        }
        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -BeExactly "result=success"
    }

    It "create_repository fails with HTTP 422" {
        Mock Invoke-WebRequest {
            [PSCustomObject]@{ StatusCode = 422; Content = '{"message": "Repository creation failed"}' }
        }
        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Error: Failed to create repository $Owner/$RepoName\. HTTP Status: 422"
    }

    It "create_repository fails with empty repo_name" {
        New-GitHubRepositoryFromTemplate -RepoName "" -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
    }

    It "create_repository fails with empty repo_description" {
        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription "" -TemplateRepo $TemplateRepo -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
    }

    It "create_repository fails with empty template_repo" {
        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo "" -Owner $Owner -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
    }

    It "create_repository fails with empty owner" {
        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner "" -Token $Token
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
    }

    It "create_repository fails with empty token" {
        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner $Owner -Token ""
        $output = Get-Content $env:GITHUB_OUTPUT
        $output | Should -Contain "result=failure"
        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
    }
	
	It "writes result=failure and error-message on exception" {
		Mock Invoke-WebRequest { throw "API Error" }

		try {
			New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner $Owner -Token $Token
		} catch {}

		$output = Get-Content $env:GITHUB_OUTPUT
		$output | Should -Contain "result=failure"
		$output | Where-Object { $_ -match "^error-message=Error: Failed to create repository $Owner/$RepoName\. Exception:" } |
			Should -Not -BeNullOrEmpty
	}	
}