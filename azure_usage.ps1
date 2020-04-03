Function Get-AzureUsage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [datetime]$FromTime,
 
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [datetime]$ToTime,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Hourly', 'Daily')]
        [string]$Interval = 'Daily'
    )
    
    Write-Verbose -Message "Querying usage data [$($FromTime) - $($ToTime)]..."
    $usageData = $null
    do {    
        $params = @{
            ReportedStartTime      = $FromTime
            ReportedEndTime        = $ToTime
            AggregationGranularity = $Interval
            ShowDetails            = $true
        }
        if ((Get-Variable -Name usageData -ErrorAction Ignore) -and $usageData) {
            Write-Verbose -Message "Querying usage data with continuation token $($usageData.ContinuationToken)..."
            $params.ContinuationToken = $usageData.ContinuationToken
        }
        $usageData = Get-UsageAggregates @params
        $usageData.UsageAggregations | Select-Object -ExpandProperty Properties
    } while ('ContinuationToken' -in $usageData.psobject.properties.name -and $usageData.ContinuationToken)
}
$usage = Get-AzureUsage -FromTime '08-30-19' -ToTime '09-30-19' -Interval Hourly -Verbose