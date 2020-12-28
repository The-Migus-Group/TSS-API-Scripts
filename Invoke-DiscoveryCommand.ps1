<#
.SYNOPSIS

Run a Thycotic Secret Server Discovery or ComputerScan

.DESCRIPTION

Call the Thycotic Secret Server REST API /Discovery/status endpoint to
check whether a Discovery or ComputerScan is already running and if not,
start it by calling the /Discovery/run endpoint.

.NOTES


Copyright 2020, The Migus Group, LLC. All rights reserved
#>

[CmdletBinding(DefaultParameterSetName = 'UserPass')]
Param(
    # The type of scan to start i.e. scan machines or the network
    [Parameter(Position = 0)][ValidateSet('ComputerScan', 'Discovery')][string]$CommandType = 'Discovery',

    # The Secret Server URI e.g. "https://webserver/SecretServer/api/v1/Discovery/status"
    [Parameter(Mandatory = $true, Position = 1)][Uri]$Uri,

    # The Secret Server access Username
    [Parameter(Mandatory = $true, ParameterSetName = 'UserPass', Position = 2)][string]$Username,

    # The corresponding Password
    [Parameter(Mandatory = $true, ParameterSetName = 'UserPass', Position = 3)][SecureString]$Password,

    # The Secret Server access Credential
    [Parameter(Mandatory = $true, ParameterSetName = 'Credential', Position = 2)][PSCredential]$Credential
)

$BaseUri = ${Uri}.ToString().TrimEnd('/')
Write-Debug "BaseUri: ${BaseUri}"

if ($Credential) {
    Write-Debug "Setting Username and Password from $Credential"
    $Username = $Credential.Username
    $Password = $Credential.Password
}
Write-Debug "Username: '${Username}' Password: $('*' * $Password.Length)"
# Call /oauth2/token then extract the access_token from the response and use it to create a the Authorization header
$Headers = @{ 'Authorization' = 'Bearer ' + (
        Invoke-WebRequest -Body (@{
                'username'   = $Username
                'password'   = $Password | ConvertFrom-SecureString -AsPlainText
                'grant_type' = 'password'
            }
        ) -Method Post -Uri "${BaseUri}/oauth2/token" -ErrorAction 'Stop' | ConvertFrom-Json).access_token
}
$DiscoveryUri = "${BaseUri}/api/v1/Discovery"

Write-Verbose 'Getting Discovery status'
$Status = Invoke-RestMethod -Headers $Headers -Uri "${DiscoveryUri}/status"
Write-Debug "Status: ${Status}"

# Do nothing if Discovery is already running
if ($CommandType -eq 'Discovery' -and $Status.isDiscoveryFetchRunning -or
    $CommandType -eq 'ComputerScan' -and $Status.isDiscoveryComputerScanRunning) {
    Write-Information "${CommandType} is already running"
    return
}
Write-Verbose "Attempting to run ${CommandType}"
# /Discovery/run returns "True" or "False", so we can cast it as boolean
if (([boolean](
            Invoke-RestMethod -Headers $Headers -ContentType 'application/json' -Body (@{
                    'data' = @{
                        'commandType' = $CommandType
                    }
                } | ConvertTo-Json) -Method Post -Uri "${discoveryUri}/run"
        ))) {
    Write-Information "${CommandType} started"
}
