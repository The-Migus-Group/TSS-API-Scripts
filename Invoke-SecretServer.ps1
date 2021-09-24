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

# SIG # Begin signature block
# MIIVjgYJKoZIhvcNAQcCoIIVfzCCFXsCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoxidZODZU1R7N9igIbbJnFnA
# VlmgghHvMIIFbzCCBFegAwIBAgIQSPyTtGBVlI02p8mKidaUFjANBgkqhkiG9w0B
# AQwFADB7MQswCQYDVQQGEwJHQjEbMBkGA1UECAwSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHDAdTYWxmb3JkMRowGAYDVQQKDBFDb21vZG8gQ0EgTGltaXRlZDEh
# MB8GA1UEAwwYQUFBIENlcnRpZmljYXRlIFNlcnZpY2VzMB4XDTIxMDUyNTAwMDAw
# MFoXDTI4MTIzMTIzNTk1OVowVjELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3Rp
# Z28gTGltaXRlZDEtMCsGA1UEAxMkU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5n
# IFJvb3QgUjQ2MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAjeeUEiIE
# JHQu/xYjApKKtq42haxH1CORKz7cfeIxoFFvrISR41KKteKW3tCHYySJiv/vEpM7
# fbu2ir29BX8nm2tl06UMabG8STma8W1uquSggyfamg0rUOlLW7O4ZDakfko9qXGr
# YbNzszwLDO/bM1flvjQ345cbXf0fEj2CA3bm+z9m0pQxafptszSswXp43JJQ8mTH
# qi0Eq8Nq6uAvp6fcbtfo/9ohq0C/ue4NnsbZnpnvxt4fqQx2sycgoda6/YDnAdLv
# 64IplXCN/7sVz/7RDzaiLk8ykHRGa0c1E3cFM09jLrgt4b9lpwRrGNhx+swI8m2J
# mRCxrds+LOSqGLDGBwF1Z95t6WNjHjZ/aYm+qkU+blpfj6Fby50whjDoA7NAxg0P
# OM1nqFOI+rgwZfpvx+cdsYN0aT6sxGg7seZnM5q2COCABUhA7vaCZEao9XOwBpXy
# bGWfv1VbHJxXGsd4RnxwqpQbghesh+m2yQ6BHEDWFhcp/FycGCvqRfXvvdVnTyhe
# Be6QTHrnxvTQ/PrNPjJGEyA2igTqt6oHRpwNkzoJZplYXCmjuQymMDg80EY2NXyc
# uu7D1fkKdvp+BRtAypI16dV60bV/AK6pkKrFfwGcELEW/MxuGNxvYv6mUKe4e7id
# FT/+IAx1yCJaE5UZkADpGtXChvHjjuxf9OUCAwEAAaOCARIwggEOMB8GA1UdIwQY
# MBaAFKARCiM+lvEH7OKvKe+CpX/QMKS0MB0GA1UdDgQWBBQy65Ka/zWWSC8oQEJw
# IDaRXBeF5jAOBgNVHQ8BAf8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zATBgNVHSUE
# DDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEMGA1Ud
# HwQ8MDowOKA2oDSGMmh0dHA6Ly9jcmwuY29tb2RvY2EuY29tL0FBQUNlcnRpZmlj
# YXRlU2VydmljZXMuY3JsMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuY29tb2RvY2EuY29tMA0GCSqGSIb3DQEBDAUAA4IBAQASv6Hvi3Sa
# mES4aUa1qyQKDKSKZ7g6gb9Fin1SB6iNH04hhTmja14tIIa/ELiueTtTzbT72ES+
# BtlcY2fUQBaHRIZyKtYyFfUSg8L54V0RQGf2QidyxSPiAjgaTCDi2wH3zUZPJqJ8
# ZsBRNraJAlTH/Fj7bADu/pimLpWhDFMpH2/YGaZPnvesCepdgsaLr4CnvYFIUoQx
# 2jLsFeSmTD1sOXPUC4U5IOCFGmjhp0g4qdE2JXfBjRkWxYhMZn0vY86Y6GnfrDyo
# XZ3JHFuu2PMvdM+4fvbXg50RlmKarkUT2n/cR/vfw1Kf5gZV6Z2M8jpiUbzsJA8p
# 1FiAhORFe1rYMIIGGjCCBAKgAwIBAgIQYh1tDFIBnjuQeRUgiSEcCjANBgkqhkiG
# 9w0BAQwFADBWMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MS0wKwYDVQQDEyRTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYw
# HhcNMjEwMzIyMDAwMDAwWhcNMzYwMzIxMjM1OTU5WjBUMQswCQYDVQQGEwJHQjEY
# MBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1Ymxp
# YyBDb2RlIFNpZ25pbmcgQ0EgUjM2MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIB
# igKCAYEAmyudU/o1P45gBkNqwM/1f/bIU1MYyM7TbH78WAeVF3llMwsRHgBGRmxD
# eEDIArCS2VCoVk4Y/8j6stIkmYV5Gej4NgNjVQ4BYoDjGMwdjioXan1hlaGFt4Wk
# 9vT0k2oWJMJjL9G//N523hAm4jF4UjrW2pvv9+hdPX8tbbAfI3v0VdJiJPFy/7Xw
# iunD7mBxNtecM6ytIdUlh08T2z7mJEXZD9OWcJkZk5wDuf2q52PN43jc4T9OkoXZ
# 0arWZVeffvMr/iiIROSCzKoDmWABDRzV/UiQ5vqsaeFaqQdzFf4ed8peNWh1OaZX
# nYvZQgWx/SXiJDRSAolRzZEZquE6cbcH747FHncs/Kzcn0Ccv2jrOW+LPmnOyB+t
# AfiWu01TPhCr9VrkxsHC5qFNxaThTG5j4/Kc+ODD2dX/fmBECELcvzUHf9shoFvr
# n35XGf2RPaNTO2uSZ6n9otv7jElspkfK9qEATHZcodp+R4q2OIypxR//YEb3fkDn
# 3UayWW9bAgMBAAGjggFkMIIBYDAfBgNVHSMEGDAWgBQy65Ka/zWWSC8oQEJwIDaR
# XBeF5jAdBgNVHQ4EFgQUDyrLIIcouOxvSK4rVKYpqhekzQwwDgYDVR0PAQH/BAQD
# AgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwMwGwYD
# VR0gBBQwEjAGBgRVHSAAMAgGBmeBDAEEATBLBgNVHR8ERDBCMECgPqA8hjpodHRw
# Oi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ1Jvb3RS
# NDYuY3JsMHsGCCsGAQUFBwEBBG8wbTBGBggrBgEFBQcwAoY6aHR0cDovL2NydC5z
# ZWN0aWdvLmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdSb290UjQ2LnA3YzAj
# BggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEM
# BQADggIBAAb/guF3YzZue6EVIJsT/wT+mHVEYcNWlXHRkT+FoetAQLHI1uBy/YXK
# ZDk8+Y1LoNqHrp22AKMGxQtgCivnDHFyAQ9GXTmlk7MjcgQbDCx6mn7yIawsppWk
# vfPkKaAQsiqaT9DnMWBHVNIabGqgQSGTrQWo43MOfsPynhbz2Hyxf5XWKZpRvr3d
# MapandPfYgoZ8iDL2OR3sYztgJrbG6VZ9DoTXFm1g0Rf97Aaen1l4c+w3DC+IkwF
# kvjFV3jS49ZSc4lShKK6BrPTJYs4NG1DGzmpToTnwoqZ8fAmi2XlZnuchC4NPSZa
# PATHvNIzt+z1PHo35D/f7j2pO1S8BCysQDHCbM5Mnomnq5aYcKCsdbh0czchOm8b
# kinLrYrKpii+Tk7pwL7TjRKLXkomm5D1Umds++pip8wH2cQpf93at3VDcOK4N7Ew
# oIJB0kak6pSzEu4I64U6gZs7tS/dGNSljf2OSSnRr7KWzq03zl8l75jy+hOds9TW
# SenLbjBQUGR96cFr6lEUfAIEHVC1L68Y1GGxx4/eRI82ut83axHMViw1+sVpbPxg
# 51Tbnio1lB93079WPFnYaOvfGAA0e0zcfF/M9gXr+korwQTh2Prqooq2bYNMvUoU
# KD85gnJ+t0smrWrb8dee2CvYZXD5laGtaAxOfy/VKNmwuWuAh9kcMIIGWjCCBMKg
# AwIBAgIQP7diHX8DAUWFQHAopWOK/DANBgkqhkiG9w0BAQwFADBUMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2MB4XDTIxMDkyMDAwMDAwMFoXDTI0
# MDkxOTIzNTk1OVowXjELMAkGA1UEBhMCVVMxETAPBgNVBAgMCERlbGF3YXJlMR0w
# GwYDVQQKDBRUaGUgTWlndXMgR3JvdXAsIExMQzEdMBsGA1UEAwwUVGhlIE1pZ3Vz
# IEdyb3VwLCBMTEMwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDL4yrq
# w8vkqKjmRwkEZjzExNryWWv9FBC9t2o94m9h7qr4H7SqsWFtF49BrlnhOeut2T5L
# gYgWzlU9e6pmUgSSLf5xOx8CcN/dqAZMM/WM30B+0ONOzbmZW6purbGGZBdBI5Y/
# du4/XXorwCoPUoAU4q57x2/Xt37teoGIvIpXtZND2bI4/UqsjPpPea352GxANB66
# ty/JrDuIE19VR0smESdrWk9OFappvKxbq/qDdJO4qEt/P10OscpxkYKUZa5E9l70
# Fx7eVX0fMgUsnQYKemKxMESo3eRRnFs1FsFpxfFOYdDsIKLDIf02KMDCqgmt5ISi
# E8PJ5Wc+7oWzg7BpCS0CYxZDvaM9CMdW1nHZDxzrbN+Dz701TxMmcXI3cw+vBcon
# 4Qz3S/fPK1jReY37LO4VkQsuVodJ/M32S3RLJytm17wKyoBSryiB/asiuJ8oUemf
# l4+9Z+XHliSJmNaYrk8EGjscsFZyzrIXFW6yTvZnVpU6MsRMHozMPA0fzojq1YT1
# 9R4xVQphU2aEb60U9WzFRjmveJtaGLBIsYPsClCdCex7rPbhNyya/peIH8KMtBXn
# 34+HAPF9mQBdVN1LyeR2iTZJHcXo9JZMM9PjQo+cUkNwg17QNhWJS680W9gJfelJ
# SVZpTB+edYEEc0L+X6G5Rn6P1GXPmtp/73qtoQIDAQABo4IBnDCCAZgwHwYDVR0j
# BBgwFoAUDyrLIIcouOxvSK4rVKYpqhekzQwwHQYDVR0OBBYEFCm/hmpmyDaG3QW0
# UBxTkY1/oObCMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBKBgNVHSAEQzBBMDUGDCsG
# AQQBsjEBAgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQ
# UzAIBgZngQwBBAEwSQYDVR0fBEIwQDA+oDygOoY4aHR0cDovL2NybC5zZWN0aWdv
# LmNvbS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdDQVIzNi5jcmwweQYIKwYBBQUH
# AQEEbTBrMEQGCCsGAQUFBzAChjhodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3Rp
# Z29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNydDAjBggrBgEFBQcwAYYXaHR0cDov
# L29jc3Auc2VjdGlnby5jb20wDQYJKoZIhvcNAQEMBQADggGBAAknDBrVkAzsAijG
# oX85rvur6pOVC/Wfw53c8PHzFQqYptANQ5Yhgsg/l6fnZEIxOAXF9fnSw/J7d9/J
# eGK6onpIgBYWjL7zOoss0olY+voSrOI9ox6en084Hg7GZASAgSUGcsJJzP2ahDoG
# lrB2bjxUmEbkW9PziqjeWnZWvYdzpJjJVFQaGIpUbcWzKVNTMw2InDdiDNk4uSrz
# KculfRFJQ6X5nRt71usF3eOg+w95WM0uYxtNY3nYQy3Ztl8RKCsWNUmqeAMeba+G
# 47BB3niivcEqqHtyDg3b1JxZcAZZVWpBoAjsbzDgxJ1nVV9CrPjoFWE2fMVlaFNv
# RRwom1AXrE2NQyQsls9RvtmaCTgRSx7PCl512kubGuC6yDXLmUdzlGZstp+F0/xb
# psNZd6q6wiXLaqULH/jih1n1+oaE82ByjvV4UgjFj9FJuDVh/HjgI0sxGJ9+tr7y
# 8UqfLQ9RuAxeiV3I4rokPEPZ3IiHdByQO0erultMQJ9vDkzTVDGCAwkwggMFAgEB
# MGgwVDELMAkGA1UEBhMCR0IxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDErMCkG
# A1UEAxMiU2VjdGlnbyBQdWJsaWMgQ29kZSBTaWduaW5nIENBIFIzNgIQP7diHX8D
# AUWFQHAopWOK/DAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKA
# ADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYK
# KwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUFE+lJIb9m7w8xSvmtQaaKYPpyRMw
# DQYJKoZIhvcNAQEBBQAEggIAGsYdftRpTf/HCDtrfXeRLxtDsdL65NI49WY8IFAR
# kU2iRxRxC8pla80bl+ilnXRm8Po7YoDG5Rkl27B+Z7M69NEVHsiOIpu+FHsB8QE9
# 8PeehdBaJVeuCFQEEBXmUJjfONjO0lvHZc97nqO0hgQHlqOFsoyYdM7OyEXaLJ5a
# bKNJYnttM+PVcndaE6JdIXOOyuJK85tUtwEilMj7c9hC/fnosNQPboSiQiwKx6Fl
# 6iYQ8wuAI+XTtJsic1sk/YYLpp4pPCYbf6qiWznkj5UMMwyWwJGA7Hinh3LjtJzK
# gs79620Wy9snmXd+vYKE4SANMH/hfNp+roySjaHg6sUoZMVsULMYn9vnSqwoT7zM
# bIipCbAS0iGqXUrE6RceGQ2ltLHW9GutQABK2tevsHWTUCJN5qNUhVtK4AIlEzpk
# UjuALTn+l7c3Wpi8PSQlBVJyC5Ppi9ST7PpnSPQ9LnFaHceXC26Ji4Vhmj+uD3y4
# +vPEkHERNJYAevVtHj2kbRaqJRI3l+h03F/xlESm96pu5z++EIxjH4Jk8EqRH7jw
# tYBeVeFmHhZi7ESo1RvwVzUh+hyEBuvNGAg5qCHznyVqqhc2q78pMF4XkzxE+EWt
# ILlCyLLqWkAslJkV7dBNbRlX1qRz8xOHY+RHyGMwJfK5tTVa2mZcatHVNAliSEN2
# 2oM=
# SIG # End signature block
