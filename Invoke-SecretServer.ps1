<#
.SYNOPSIS

Call the Thycotic Secret Server REST API

.DESCRIPTION

Call the Thycotic Secret Server REST API using Invoke-RestMethod

.LINK

    Invoke-RestMethod

.LINK

    ConvertTo-Json

.INPUTS

The object to be serialized to JSON and sent as the request body

.OUTPUTS

The ouput of the Invoke-RestMethod call

.EXAMPLE

# Make a single call
PS > Invoke-SecretServer.ps1 /api/v1/Discovery/status (Get-Credential) https://webserver/SecretServer

.EXAMPLE

# Set the Credential and BaseUrl Parameters for the duration of the PSSession
PS > $PSDefaultParameterValues['Invoke-SecretServer.ps1:Credential'] = Get-Credential
PS > $PSDefaultParameterValues['Invoke-SecretServer.ps1:BaseUrl'] = 'https://webserver/SecretServer'
# ...
PS > # Then call the REST API using only the URI
PS > Invoke-SecretServer.ps1 /api/v1/Discovery/status

.EXAMPLE

# Provide $RequestBody via the Pipeline
PS > @{ "data" = @{ "commandType" = "Discovery" } } | ConvertTo-Json |
>> .\Invoke-SecretServer.ps1 /api/v1/Discovery/run

.NOTES

The script gets a new access_token for to every request and does not cache or refresh it


Copyright (c) 2020, The Migus Group, LLC. All rights reserved
#>

#region Parameters
[CmdletBinding(DefaultParameterSetName = 'UserPass')]
Param(
    # The Secret Server URI e.g. "/api/v1/Discovery/status"
    [Parameter(Mandatory = $true, Position = 0)][Uri]$Uri,

    # The Secret Server access Username
    [Parameter(Mandatory = $true, ParameterSetName = "UserPass", Position = 1)][string]$Username,

    # The corresponding Password
    [Parameter(Mandatory = $true, ParameterSetName = "UserPass", Position = 2)][SecureString]$Password,

    # The Secret Server access Credential
    [Parameter(Mandatory = $true, ParameterSetName = "Credential", Position = 1)][PSCredential]$Credential,

    # The base URL of the Secret Server e.g. "https://servername/SecretServer"
    [Uri]$BaseUrl = $env:TSS_URL,

    # HTTP request method e.g. POST
    [ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')][string]$Method = 'GET',

    # The body of the request for POST, PUT...
    [Parameter(ValueFromPipeline = $true, Position = 3)][PSObject]$RequestBody
)

Write-Debug "BaseUrl is ${BaseUrl}"
#endregion

#region Token Request
if ($Credential) {
    Write-Debug 'Setting Username and Password from $Credential'
    $Username = $Credential.Username
    $Password = $Credential.Password
}
Write-Debug "Username: ${Username} Password: $('*' * $Password.Length)"
# Call /oauth2/token then extract the access_token from the response and use it to create a the Authorization header
$InvokeRestMethodParameters = @{
    Headers = @{ 'Authorization' = 'Bearer ' + (
            Invoke-WebRequest -Body (@{
                    'username'   = $Username
                    'password'   = $Password | ConvertFrom-SecureString -AsPlainText
                    'grant_type' = 'password'
                }
            ) -Method Post -Uri "${BaseUrl}/oauth2/token" -ErrorAction 'Stop' | ConvertFrom-Json).access_token
    }
    Method  = $Method
    Uri = '{0}/{1}' -f $BaseUrl.ToString().TrimEnd('/'), $Uri.ToString().TrimStart('/')
}
#endregion

#region API Request
if ($RequestBody) {
    if ('GET' -eq $Method) {
        Write-Debug 'Changing $Method from GET to POST because $RequestBody is present'
        $InvokeRestMethodParameters['Method'] = 'POST'
    }
    Write-Debug 'Adding $RequestBody to the request'
    $InvokeRestMethodParameters['Body'] = ConvertTo-Json $RequestBody
    $InvokeRestMethodParameters['ContentType'] = 'application/json'
}

Invoke-RestMethod @InvokeRestMethodParameters
#endregion
