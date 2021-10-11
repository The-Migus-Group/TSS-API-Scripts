# TSS-API-Scripts

Wrapper scripts that [The Migus Group](https://migusgroup.com) use to implement
scripting and automation use-cases for [Thycotic](https://thycotic.com/)
[Secret Server](https://thycotic.com/products/secret-server/) users.

NOTE: Thycotic recommends their
[PowerShell Module](https://www.powershellgallery.com/packages/Thycotic.SecretServer)
which they distribute via [PSGallery](https://www.powershellgallery.com/) for automation use-cases.
It fully integrates Secret Server with PowerShell.

## Example Usage

### Set up the Environment

#### Using `Initialize.ps1`

##### Interactively

```PowerShell
. .\Initialize.ps1

cmdlet Initialize.ps1 at command pipeline position 1
Supply values for the following parameters:
Credential
User: admin
Password for user admin: ************

Url: https://tssweb
```

##### Using Parameters

```PowerShell
. .\Initialize.ps1 -Credential (Get-Credential) -Url 'https://tssweb'
```

Or

```PowerShell
. .\Initialize.ps1 -Credential (Get-Credential) -Tenant 'mytenant'
```

#### Using the SDK Client for DevOps

1. Put the three scripts in a folder that is in your `$env:Path`
2. [Download](https://docs.thycotic.com/ss/10.9.0/api-scripting/sdk-downloads#downloads) and extract the
   [Secret Server SDK for DevOps](https://docs.thycotic.com/ss/10.9.0/api-scripting/sdk-cli/index.md)

##### Set some defaults

```PowerShell
$PSDefaultParameterValues['Invoke-Tss.ps1:ExePath'] = "C:\secretserver-sdk-*-win-x64\tss.exe"
$PSDefaultParameterValues['Invoke-Tss.ps1:ConfigDirPath'] = "${env:USERPROFILE}\.tss"
$PSDefaultParameterValues['Invoke-SecretServer.ps1:BaseUrl'] = 'https://my.local/SecretServer'
$PSDefaultParameterValues['Invoke-SecretServer.ps1:AccessToken'] = { Invoke-Tss.ps1 token }

Set-Alias -Name 'tss' -Value Invoke-Tss
```

##### Initialize the SDK Client

```PowerShell
tss init -- -k '...' -r Rule -u https://my.local/SecretServer/

```

### Call Secret Server

```PowerShell
Invoke-SecretServer.ps1 /version
```
