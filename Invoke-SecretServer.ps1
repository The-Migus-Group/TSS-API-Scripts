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
PS > Invoke-SecretServer.ps1 /Discovery/status (Get-Credential) https://webserver/SecretServer

.EXAMPLE

# Set the Credential and BaseUrl Parameters for the duration of the PSSession
PS > $PSDefaultParameterValues['Invoke-SecretServer.ps1:Credential'] = Get-Credential
PS > $PSDefaultParameterValues['Invoke-SecretServer.ps1:BaseUrl'] = 'https://webserver/SecretServer'
# ...
PS > # Then call the REST API using only the URI
PS > Invoke-SecretServer.ps1 /Discovery/status

.EXAMPLE

# Provide $RequestBody via the Pipeline
PS > @{ "data" = @{ "commandType" = "Discovery" } } | ConvertTo-Json |
>> .\Invoke-SecretServer.ps1 /Discovery/run

.NOTES

The script gets a new access_token for to every request and does not cache or refresh it


Copyright (c) 2020, The Migus Group, LLC. All rights reserved
#>

#region Parameters
[CmdletBinding(DefaultParameterSetName='Credential')]
Param(
    # The Secret Server URI e.g. "/Discovery/status"
    [Parameter(Mandatory = $true, Position = 0)][Uri]$Uri,

    # The base URL of the Secret Server e.g. "https://my.local/SecretServer/"
    [Parameter(Mandatory = $true, Position = 1)][Uri]$BaseUrl,

    # A Secret Server REST API (OAuth2) access_token
    [Parameter(Mandatory = $true, ParameterSetName = 'AccessToken', Position = 2)][string]$AccessToken,

    # The Secret Server access Username
    [Parameter(Mandatory = $true, ParameterSetName = 'UserPass', Position = 2)][string]$Username,

    # The corresponding Password
    [Parameter(Mandatory = $true, ParameterSetName = 'UserPass', Position = 3)][SecureString]$Password,

    # The Secret Server access Credential
    [Parameter(Mandatory = $true, ParameterSetName = 'Credential', Position = 2)][PSCredential]$Credential,
    # HTTP request method e.g. POST
    [Parameter(Position = 3)][ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')][string]$Method = 'GET',

    # The body of the request for POST, PUT...
    [Parameter(Position = 4, ValueFromPipeline = $true)][PSObject]$Body,

    [Parameter()][Uri]$ApiUri = '/api/v1',

    [Parameter()][Uri]$TokenUri = '/oauth2/token'
)
#endregion

#region Token Request
if ($PSCmdlet.ParameterSetName -eq 'Credential') {
    $Username = $Credential.UserName
    $Password = $Credential.Password
}

if ($PSCmdlet.ParameterSetName -in @('Credential', 'UserPass')) {
    $AccessToken = (Invoke-WebRequest -Body (@{
                'username'   = $Username
                'password'   = $Password | ConvertFrom-SecureString -AsPlainText
                'grant_type' = 'password'
            }) -Method Post -Uri (
            '{0}/{1}' -f $BaseUrl.ToString().TrimEnd('/'), $TokenUri.ToString().Trim('/')
        ) -ErrorAction 'Stop' | ConvertFrom-Json | Select-Object -ExpandProperty 'access_token')
}
#endregion

#region API Request
$InvokeRestMethodParameters = @{
    Headers = @{ 'Authorization' = 'Bearer ' + $AccessToken }
    Method  = $Method
    Uri     = '{0}/{1}/{2}' -f $BaseUrl.ToString().TrimEnd('/'), $ApiUri.ToString().Trim('/'), $Uri.ToString().TrimStart('/')
}

if ($Body) {
    if ('GET' -eq $Method) {
        Write-Debug 'Changing $Method from GET to POST because $RequestBody is present'
        $InvokeRestMethodParameters['Method'] = 'POST'
    }
    Write-Debug 'Sending JSON representation of $RequestBody'
    $InvokeRestMethodParameters['Body'] = ConvertTo-Json $Body
    $InvokeRestMethodParameters['ContentType'] = 'application/json'
}
Invoke-RestMethod @InvokeRestMethodParameters
#endregion
