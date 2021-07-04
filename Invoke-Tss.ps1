<#
.SYNOPSIS
Invokes tss.exe from the Thycotic Secret Server SDK for DevOps

.DESCRIPTION
Invokes tss.exe from the Thycotic Secret Server SDK for DevOps, supplying a location for the executable and an explicit
argument for the configuration directory.

.EXAMPLE
# Set the ExePath and ConfigDirPath Parameters for the duration of the PSSession
PS > $PSDefaultParameterValues['Invoke-Tss.ps1:ConfigDirPath'] = "${env:USERPROFILE}\.tss"
PS > $PSDefaultParameterValues['Invoke-Tss.ps1:ExePath'] = "C:\secretserver-sdk-*-win-x64\tss.exe"

# Alias the wrapper to tss
PS > Set-Alias -Name 'tss' -Value Invoke-Tss.ps1

PS > # Then call tss from anywhere with the same configuration
PS > tss status
#>
[CmdletBinding()]
Param(
    [Parameter()][String]$ConfigDirPath = '.',
    [Parameter()][String]$ExePath = (Get-Command tss.exe | Select-Object -ExpandProperty Source),
    [Parameter(Position = 0, ValueFromRemainingArguments)]$RemainingArguments
)

$Expression = "${ExePath} -cd ${ConfigDirPath} ${RemainingArguments}"

Write-Debug "Invoking $Expression"
Invoke-Expression $Expression

# Copyright (c) 2021, The Migus Group, LLC. All rights reserved
