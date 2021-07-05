# TSS-API-Scripts

Scripts that [Migus Group](https://migusgroup.com) consultants use to implement
scripting and automation use-cases for [Thycotic](https://thycotic.com/)
[Secret Server](https://thycotic.com/products/secret-server/) users.

## Example Usage

### Prepare the environment

1. Put the three scripts in a folder that is in your `$env:Path`
2. [Download](https://docs.thycotic.com/ss/10.9.0/api-scripting/sdk-downloads#downloads) and extract the
   [Secret Server SDK for DevOps](https://docs.thycotic.com/ss/10.9.0/api-scripting/sdk-cli/index.md)

### Set some defaults

```PowerShell
$PSDefaultParameterValues['Invoke-Tss.ps1:ExePath'] = "C:\secretserver-sdk-*-win-x64\tss.exe"
$PSDefaultParameterValues['Invoke-Tss.ps1:ConfigDirPath'] = "${env:USERPROFILE}\.tss"
$PSDefaultParameterValues['Invoke-SecretServer.ps1:BaseUrl'] = 'https://my.local/SecretServer'
$PSDefaultParameterValues['Invoke-SecretServer.ps1:AccessToken'] = { Invoke-Tss.ps1 token }

Set-Alias -Name 'tss' -Value Invoke-Tss
```

### Initialize the SDK Client

```PowerShell
tss init -- -k '...' -r Rule -u https://my.local/SecretServer/

```

### Call Secret Server

```PowerShell
Invoke-SecretServer.ps1 /version
```
