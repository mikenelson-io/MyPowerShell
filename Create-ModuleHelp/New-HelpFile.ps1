<#
    .SYNOPSIS
    Builds templated Help content output from a PowerShell module.
    .DESCRIPTION
    Given a imported module name, this cmdlet will output the help content of said mnodule in the desired templated format. Formats included are HTML, Markdown, or Markup.
    .PARAMETER moduleName
    Required. Name of imported module in the current session.
    .PARAMETER template
    Optional. Filename with path of the template to use. Included tempates are out-html-template.ps1, out-markdown-template.ps1, or out-confluence-markup-template.ps1.
    If not specified, defaults to ./out-html-template.ps1. This file must exist in the path specified.
    .PARAMETER outputDir
    Optional. Folder to place the output file to. If the folder does not exist, it will be created.
    If not specified, defaults to current folder.
    .PARAMETER filename
    Optional. The name of the output file.
    If not specified, defaults to index.html for HTML.
    .INPUTS
    None
    .OUTPUTS
    Help content in desired format.
    .EXAMPLE
    New-HelpFile.ps1 -moduleName myModule

    Crates an HTML file with the modules' help content in the current folder.
    .EXAMPLE
    New-HelpFile.ps1 -moduleName myModule -template out-markdown-template.ps1

    Creates an markdown (.md) file with the modules' help content in the curret folder.
    #>
[CmdletBinding()]
param(
    [parameter(Mandatory=$true, Position=0)] [string] $moduleName,
    [parameter(Mandatory=$false, Position=1)] [string] $template = "./out-html-template.ps1",
    [parameter(Mandatory=$false, Position=2)] [string] $outputDir = "./",
    [parameter(Mandatory=$false, Position=3)] [string] $fileName = "index.html"
)

$moduleVersion = Get-Module -Name $moduleName | Select-Object -Property Version | ConvertTo-Html -Fragment -As List

function FixString ($in = '', [bool]$includeBreaks = $false){
    if ($null -eq $in) { return }

    $rtn = $in.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Trim()

    if($includeBreaks){
        $rtn = $rtn.Replace([Environment]::NewLine, '<br>')
    }
    return $rtn
}

function Update-Progress($name, $action){
    Write-Progress -Activity "Rendering $action for $name" -CurrentOperation "Completed $progress of $totalCommands." -PercentComplete $(($progress/$totalCommands)*100)
}
$i = 0
$commandsHelp = (Get-Command -module $moduleName) | get-help -full | Where-Object {! $_.name.EndsWith('.ps1')}

foreach ($h in $commandsHelp){
    $cmdHelp = (Get-Command $h.Name)

    # Get any aliases associated with the method
    $alias = get-alias -definition $h.Name -ErrorAction SilentlyContinue
    if($alias){
        $h | Add-Member Alias $alias
    }

    # Parse the related links and assign them to a links hashtable.
    if(($h.relatedLinks | Out-String).Trim().Length -gt 0) {
        $links = $h.relatedLinks.navigationLink | % {
            if($_.uri){ @{name = $_.uri; link = $_.uri; target='_blank'} }
            if($_.linkText){ @{name = $_.linkText; link = "#$($_.linkText)"; cssClass = 'psLink'; target='_top'} }
        }
        $h | Add-Member Links $links
    }

    # Add parameter aliases to the object.
    foreach($p in $h.parameters.parameter ){
        $paramAliases = ($cmdHelp.parameters.values | Where-Object name -like $p.name | Select-Object aliases).Aliases
        if($paramAliases){
            $p | Add-Member Aliases "$($paramAliases -join ', ')" -Force
        }
    }
}

# Create the output directory if it does not exist
if (-Not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

$totalCommands = $commandsHelp.Count
if (!$totalCommands) {
    $totalCommands = 1
}

$template = Get-Content $template -raw -force
Invoke-Expression $template > "$outputDir\$fileName"

## END