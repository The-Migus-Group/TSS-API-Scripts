<#
.SYNOPSIS

Get an OAuth2 access_token from Thycotic Secret Server

.DESCRIPTION

Get an OAuth2 access_token from Thycotic Secret Server using a password authentication
#>

#region Parameters
[CmdletBinding(DefaultParameterSetName = 'Credential')]
Param(
    # The endpoint e.g. "https://my.local/SecretServer/oauth2/token"
    [Parameter(Mandatory, Position = 0)][Uri]$Uri,

    # The Username
    [Parameter(Mandatory, ParameterSetName = 'UserPass', Position = 1)][string]$Username,

    # The corresponding Password
    [Parameter(Mandatory, ParameterSetName = 'UserPass', Position = 2)][SecureString]$Password,

    # The Credential
    [Parameter(Mandatory, ParameterSetName = 'Credential', Position = 1, ValueFromPipeline)][PSCredential]$Credential
)
#endregion

#region AccessToken Request
if ($PSCmdlet.ParameterSetName -eq 'Credential') {
    ($Username, $Domain) = if ($Credential.GetNetworkCredential().Domain) {
        $Credential.GetNetworkCredential().UserName,
        $Credential.GetNetworkCredential().Domain
    }
    else {
        $Credential.UserName
    }
    $Password = $Credential.Password
    Write-Debug "Username is ${Username}; Domain is ${Domain}; Password is $($Password -replace '.', '*')"
}

# PowerShell prior to 7.x does not let you convert a secure string to the plaintext using ConvertFrom-SecureString. See:
# https://stackoverflow.com/questions/60010511/powershell-error-when-converting-a-securestring-back-to-plain-text
$Body = @{
    'username'   = $Username
    'password'   = if ($PSVersionTable.PSVersion.Major -ge 7) {
        $Password | ConvertFrom-SecureString -AsPlainText
    }
    else {
        [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
    }
    'grant_type' = 'password'
}

if ($Domain) {
    $Body['domain'] = $Domain
    Write-Debug 'Adding $Domain to the $Body'
}
Write-Debug "Body (except 'password') = $($Body | Select-Object -ExcludeProperty 'password')"
Invoke-WebRequest -Uri $Uri -Method Post -Body $Body | ConvertFrom-Json
| Select-Object -ExpandProperty 'access_token'
#endregion

# Copyright (c) 2021, The Migus Group, LLC. All rights reserved
