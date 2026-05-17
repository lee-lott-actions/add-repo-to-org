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
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
	    It "unit: New-GitHubRepositoryFromTemplate succeeds with HTTP 201" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 201; Content = '{"message": "Repository created"}' }
	        }
	        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -BeExactly "result=success"
	    }	
	}
	
	Context "HTTP Failure Cases" {
	    It "unit: New-GitHubRepositoryFromTemplate fails with HTTP 422" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 422; Content = '{"message": "Repository creation failed"}' }
	        }
	        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Error: Failed to create repository $Owner/$RepoName. HTTP Status: 422"
	    }
	}

	Context "Parameter Validation Failure Cases" {
		It "unit: New-GitHubRepositoryFromTemplate fails with empty RepoName" {
	        New-GitHubRepositoryFromTemplate -RepoName "" -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
	    }
	
	    It "unit: New-GitHubRepositoryFromTemplate fails with empty RepoDescription" {
	        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription "" -TemplateRepo $TemplateRepo -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
	    }
	
	    It "unit: New-GitHubRepositoryFromTemplate fails with empty TemplateRepo" {
	        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo "" -Owner $Owner -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
	    }
	
	    It "unit: New-GitHubRepositoryFromTemplate fails with empty Owner" {
	        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner "" -Token $Token
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
	    }
	
	    It "unit: New-GitHubRepositoryFromTemplate fails with empty Token" {
	        New-GitHubRepositoryFromTemplate -RepoName $RepoName -RepoDescription $RepoDescription -TemplateRepo $TemplateRepo -Owner $Owner -Token ""
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: repo_name, repo_description, template_repo, owner, and token must be provided."
	    }
	}
	
	Context "Exception Failure Cases" {
		It "unit: New-GitHubRepositoryFromTemplate fails with exception" {
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
}
