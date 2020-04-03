# Thanks to Jaap Brasser

get-childitem | % {
    $GHPath = $_.FullName -replace 'D:\\onedrive\\github\\repo\\mikenelson-io\\MyPresentations' -replace '\\','/' -replace '\s','%20'
    "* [$(Split-Path $_ -Leaf)](https://github.com/mikenelson-io/MyPresentations/tree/master$GHPath)"
    $_ | ls -recurse | ? {$_.PSIsContainer -or $_.Extension -eq '.md'} | select -exp fullname | % {
        $Count = ($_ -split '\\').Count -7
        $GHPath = $_ -replace 'D:\\onedrive\\github\\repo\\mikenelson-io\\MyPresentations' -replace '\\','/' -replace '\s','%20'
        "$(" "*$Count*2)* [$(Split-Path $_ -Leaf)](https://github.com/mikenelson-io/events/tree/master$GHPath)"
    }
} | clip.exe
