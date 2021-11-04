<#PSScriptInfo

.VERSION 0.1.0

.GUID 05c41fde-bd40-4dd3-a72e-12ec14a50676

.AUTHOR Tyler Leonhardt

.COMPANYNAME Tyler Leonhardt

.COPYRIGHT (c) Tyler Leonhardt

.TAGS snippets vscode converter

.LICENSEURI https://github.com/PowerShell/PowerShell/blob/master/LICENSE.txt

.PROJECTURI https://gist.github.com/tylerl0706/3d1618572f7a424dab812e9cce5e3a15

.ICONURI https://gist.github.com/tylerl0706/3d1618572f7a424dab812e9cce5e3a15#file-license-txt

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
# 0.1.0

Initial Release


.PRIVATEDATA

#>

<#
.SYNOPSIS
A PowerShell script to help create VSCode snippets.

.DESCRIPTION
A PowerShell script to help create VSCode snippets. For more information on snippets, please see: https://code.visualstudio.com/docs/editor/userdefinedsnippets

.PARAMETER Name
The name of the snippet.

.PARAMETER Body
The body of the snippet. This is the actual content.

.PARAMETER Prefix
The prefix used when selecting the snippet in intellisense.

.PARAMETER Scope
A list of language names to which this snippet applies. If left blank, it will apply to all languages.

.PARAMETER Description
The snippet description.

.PARAMETER IndentationType
The indentation you want to use. Options are: Tabs, 2Spaces, 4Spaces. 4Spaces is the default.

.EXAMPLE
$body = "
Get-Process
$hello = 'World'
$hello
"
# Take a string and turn it into a snippet
./ConvertTo-VSCodeSnippet.ps1 -Name Foo -Body $body -Scope 'powershell'

.EXAMPLE
# Without Scope, this snippet will apply to all languages
./ConvertTo-VSCodeSnippet.ps1 -Name Foo -Body $body

.EXAMPLE
# Body is also accepted from the pipeline
$body | ./ConvertTo-VSCodeSnippet.ps1 -Name Foo

.EXAMPLE
# Full invocation
./ConvertTo-VSCodeSnippet.ps1 -Name Foo -Body content -Scope 'powershell','javascript' -Prefix foo -Description 'The best'

#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    $Name,

    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]
    $Body,

    [Parameter()]
    [string]
    $Prefix = $Name,

    [Parameter()]
    [string[]]
    $Scope,

    [Parameter()]
    [string]
    $Description,

    [ValidateSet('Tabs','2Spaces','4Spaces')]
    [string]
    $IndentationType = '4Spaces'
)

function EscapeString {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]
        $Value,

        [Parameter(Mandatory=$true)]
        [string[]]
        $Escape
    )

    $result = $Value
    $Escape | ForEach-Object { $result = $result -replace $_, "\$_" }
    $result
}

# Set the indentation type
if ($IndentationType -eq '4Spaces') {
    $indent = ' '
} elseif ($IndentationType -eq '2Spaces') {
    $indent = ' '
} else {
    $indent = "`t"
}

# Normalize string and split it by newline character. Also wrap it's line in quotes.
$result = (EscapeString -Value $Body -Escape '\$','"') `
    -split [System.Environment]::NewLine |
    ForEach-Object { "`"$_`"" }

# Wrap the previous result in the json property string
$bodyProp = "`n$indent`"body`":[
$indent$indent$($result -join ",`n$indent$indent")
$indent]"

# Wrap the prefix in the json property string
$prefixProp = "$indent`"prefix`":`"$Prefix`","

# If a scope is specified, wrap it in the json property string
if($Scope) {
    $scopeProp = "`n$indent`"scope`":`"$($Scope -join ',')`","
} else {
    $scopeProp = ""
}

# If a description is specified, wrap it in the json property string
if($Description) {
    $descriptionProp = "`n$indent`"description`":`"$(EscapeString -Value $Description -Escape '"')`","
} else {
    $descriptionProp = ""
}

# Return the full snippet
"`"$(EscapeString -Value $Name -Escape '"')`": {
$prefixProp$scopeProp$descriptionProp$bodyProp
}"
