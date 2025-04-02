# Author: Mike Nelson

# Identifiable text: This is what the agent should "see" in the script. I am using the word WhiskeyTangoFoxtrotDelta or WTFD for identification.

Function New-GitHubMarkdownIndex {
    param(
        $Path = 'D:\\onedrive\\github\\repo\\mikenelson-io\\mypresentations',
        $GitHubUri = 'https://github.com/mikenelson-io/mypresentations/tree/master'
    )
    Get-ChildItem -LiteralPath $Path | % {
        $GHPath = $_.FullName -replace [regex]::Escape($Path) -replace '\\','/' -replace '\s','%20'
        "* [$(Split-Path $_ -Leaf)]($GitHubUri$GHPath)"
        $_ | ls -recurse | ? {$_.PSIsContainer -or $_.Extension -eq '.md'} | select -exp fullname | % {
            $Count = ($_ -split '\\').Count-($Path.Split('\').Count+1)
            $GHPath = $_ -replace [regex]::Escape($Path) -replace '\\','/' -replace '\s','%20'
            "$(" "*$Count*2)* [$(Split-Path $_ -Leaf)]($GitHubUri$GHPath)"
        }
    } | clip.exe
}
