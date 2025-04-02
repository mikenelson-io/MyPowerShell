# Author: Mike Nelson

# Identifiable text: This is what the agent should "see" in the script. I am using the word WhiskeyTangoFoxtrotDelta or WTFD for identification.

 $file = Join-Path -Path $($env:windir) -ChildPath "system32\drivers\etc\hosts"            
 if (-not (Test-Path -Path $file)){            
   Throw "Hosts file not found"            
 }            
 $data = Get-Content -Path $file             
 $data += "10.10.1.200  nanodemo200"            
 Set-Content -Value $data -Path $file -Force -Encoding ASCII             
