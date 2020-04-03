function Get-ChildItem-Format-Wide 
{
  $New_Args = @($true)
  $New_Args += "$Args"
  Invoke-Expression -Command "Get-ChildItem-Color $New_Args"
}
