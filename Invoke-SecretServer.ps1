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
PS > Invoke-SecretServer.ps1 /Discovery/status https://webserver/SecretServer

.EXAMPLE

# Set the Credential and BaseUrl Parameters for the duration of the PSSession
PS > $PSDefaultParameterValues['Invoke-SecretServer.ps1:Credential'] = Get-Credential
PS > $PSDefaultParameterValues['Invoke-SecretServer.ps1:BaseUrl'] = 'https://webserver/SecretServer'
# ...
PS > # Then call the REST API using only the URI
PS > Invoke-SecretServer.ps1 /Discovery/status

.EXAMPLE

# Provide $RequestBody via the Pipeline
PS > @{ "data" = @{ "commandType" = "Discovery" } } | Invoke-SecretServer.ps1 /Discovery/run
#>

#region Parameters
[CmdletBinding(DefaultParameterSetName = 'Credential')]
Param(
    # The base URL of the Secret Server e.g. "https://my.local/SecretServer/"
    [Parameter(Mandatory, Position = 1)][Uri]$BaseUrl,

    # The Secret Server URI e.g. "/Discovery/status"
    [Parameter(Mandatory, Position = 0)][Uri]$Uri,

    # A Secret Server REST API (OAuth2) access_token
    [Parameter(Mandatory, ParameterSetName = 'AccessToken', Position = 2)][string]$AccessToken,

    # The Secret Server access Credential
    [Parameter(Mandatory, ParameterSetName = 'Credential', Position = 2)][PSCredential]$Credential,

    # The Secret Server access Username
    [Parameter(Mandatory, ParameterSetName = 'UserPass', Position = 2)][string]$Username,

    # The corresponding Password
    [Parameter(Mandatory, ParameterSetName = 'UserPass', Position = 3)][SecureString]$Password,

    # HTTP request method e.g. POST
    [Parameter(Position = 3)][ValidateSet('GET', 'POST', 'PUT', 'PATCH', 'DELETE')][string]$Method = 'GET',

    # The body of the request for POST, PUT...
    [Parameter(Position = 4, ValueFromPipeline)][PSObject]$BodyObject,

    [Parameter()][Uri]$ApiUri = '/api/v1',

    [Parameter()][Uri]$TokenUri = '/oauth2/token'

)
#endregion

function Script:SecretServerUrl {
    [CmdletBinding()]Param([Parameter(Mandatory)][Uri] $Uri)

    '{0}/{1}' -f $BaseUrl.ToString().TrimEnd('/'), $Uri.ToString().Trim('/')
}

#region Token Request
if ($PSCmdlet.ParameterSetName -in @('Credential', 'UserPass')) {
    $TokenEndpointUrl = SecretServerUrl $TokenUri
    $GetAccessTokenParameters = @{
        Uri = $TokenEndpointUrl
    }

    Write-Debug "Getting an OAuth2 access_token from the ${TokenEndpointUrl}"
    if ($PSCmdlet.ParameterSetName -eq 'UserPass') {
        Write-Debug 'Using $Username and $Password'
        $GetAccessTokenParameters += @{
            Username = $Username
            Password = $Password
        }
    }
    else {
        Write-Debug 'Using $Credential'
        $GetAccessTokenParameters['Credential'] = $Credential
    }
    $AccessToken = & Get-SecretServerAccessToken.ps1 @GetAccessTokenParameters
}
#endregion

#region API Request
$InvokeRestMethodParameters = @{
    Headers = @{ 'Authorization' = 'Bearer ' + $AccessToken }
    Method  = $Method
    Uri     = '{0}/{1}' -f (SecretServerUrl $ApiUri), $Uri.ToString().TrimStart('/')
}

if ($BodyObject) {
    $Body = ConvertTo-Json $BodyObject

    if ('GET' -eq $Method) {
        Write-Debug 'Changing $Method from GET to POST because $BodyObject is present'
        $InvokeRestMethodParameters['Method'] = 'POST'
    }
    Write-Debug "Body = $Body"
    $InvokeRestMethodParameters += @{
        Body        = $Body
        ContentType = 'application/json'
    }
}
Invoke-RestMethod @InvokeRestMethodParameters
#endregion

# Copyright (c) 2021, The Migus Group, LLC. All rights reserved
