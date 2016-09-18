[CmdletBinding()]
param(
    [string] $SharePointCmdletModule = (Join-Path $PSScriptRoot "..\Stubs\SharePoint\15.0.4805.1000\Microsoft.SharePoint.PowerShell.psm1" -Resolve)
)

$ErrorActionPreference = 'stop'
Set-StrictMode -Version latest

$RepoRoot = (Resolve-Path $PSScriptRoot\..\..\..).Path
$Global:CurrentSharePointStubModule = $SharePointCmdletModule 

$ModuleName = "MSFT_SPPublishServiceApplication"
Import-Module (Join-Path $RepoRoot "Modules\SharePointDsc\DSCResources\$ModuleName\$ModuleName.psm1") -Force

Describe "SPPublishServiceApplication - SharePoint Build $((Get-Item $SharePointCmdletModule).Directory.BaseName)" {
    InModuleScope $ModuleName {
        $testParams = @{
            Name = "Managed Metadata"
            Ensure = "Present"
        }
        Import-Module (Join-Path ((Resolve-Path $PSScriptRoot\..\..\..).Path) "Modules\SharePointDsc")
        
        Mock Invoke-SPDSCCommand { 
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }
        
        Remove-Module -Name "Microsoft.SharePoint.PowerShell" -Force -ErrorAction SilentlyContinue
        Import-Module $Global:CurrentSharePointStubModule -WarningAction SilentlyContinue 
        Mock Publish-SPServiceApplication { }
        Mock Unpublish-SPServiceApplication { }

        Context "An invalid service application is specified to be published" {
            Mock Get-SPServiceApplication  { return $null }
            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws when the set method is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        Context "The service application is not published but should be" {
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    Name = $testParams.Name
                    Uri = "urn:schemas-microsoft-com:sharepoint:service:mmsid"
                    Shared = $false
                }
                return $spServiceApp
            }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the Publish-SPServiceApplication call from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Publish-SPServiceApplication
            }
        }

        Context "The service application is published and should be" {
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    Name = $testParams.Name
                    Uri = "urn:schemas-microsoft-com:sharepoint:service:mmsid"
                    Shared = $true
                }
                return $spServiceApp
            }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The service application specified does not exist" {
            Mock Get-SPServiceApplication  { return $null }
                        
            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "throws when the set method is called" {
                { Set-TargetResource @testParams } | Should Throw
            }
        }

        $testParams.Ensure = "Absent"

        Context "The service application is not published and should not be" {
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    Name = $testParams.Name
                    Uri = "urn:schemas-microsoft-com:sharepoint:service:mmsid"
                    Shared = $false
                }
                return $spServiceApp
            }

            It "returns absent from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "returns true from the test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context "The service application is published and should not be" {
            Mock Get-SPServiceApplication {
                $spServiceApp = [pscustomobject]@{
                    Name = $testParams.Name
                    Uri = "urn:schemas-microsoft-com:sharepoint:service:mmsid"
                    Shared = $true
                }
                return $spServiceApp
            }

            It "returns present from the get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "returns false from the test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "calls the Unpublish-SPServiceApplication call from the set method" {
                Set-TargetResource @testParams

                Assert-MockCalled Unpublish-SPServiceApplication
            }
        }
    }    
}
