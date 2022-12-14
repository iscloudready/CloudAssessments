#region System Variables
$organization = ""
$project = ""
$repositoryName = ""
$repositoryId = ""
$method = "GET"
$orgUrl = "https://dev.azure.com/$organization"
$url = "$orgUrl/$project/_apis/git/repositories/$repositoryId/commits?"
$queryString = "api-version=6.0"
$patToken = ""
$contentType = "application/json"
$basePath = "C:\\"
$Path = "$basePath$project"
$networkPath = "\\Share" 
#endregion System Variables

#region Application settings
$fromDate = "6/11/2017 12:00:00 AM" 
$toDate = "6/12/2017 12:00:00 AM" 

$fromCommitId = "55b7d182e38aec0cf0579793c05c5f0cc4eab098" 
$toCommitId = "59381fd6911877566ca37acd87c03b73fe073c27" 

$filteredRangeFilePath = "$basePath\filteredRange.json"
#endregion Application settings

#region Authorization
# Define organization base url, PAT and API version variables
# Create header with PAT The Header is created with the given information.
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($patToken)"))

$Header = @{
    Authorization = ("Basic {0}" -f $token)
}
#endregion Authorization

#region Request Processing
function CreateDateRangeFilterUrl {
    param(
        [Parameter (Mandatory = $true)] [String]$URL,
        [Parameter (Mandatory = $true)] [String]$fromDate,
        [Parameter (Mandatory = $true)] [String]$toDate
    )
    if ([string]::IsNullOrEmpty($URL) -or [string]::IsNullOrEmpty($fromDate) -or [string]::IsNullOrEmpty($toDate)) {
        return
    }

    $formattedUrl = "$($URL)searchCriteria.fromDate=$($fromDate)&searchCriteria.toDate=$($toDate)&$($queryString)"
    Write-Host "Date Range filtered url $($formattedUrl)"
    return $formattedUrl  
}

function CreateCommitIdRangeFilter {
    param(
        [Parameter (Mandatory = $true)] [String]$URL,
        [Parameter (Mandatory = $true)] [String]$fromCommitId,
        [Parameter (Mandatory = $true)] [String]$toCommitId
    )
    if ([string]::IsNullOrEmpty($URL) -or [string]::IsNullOrEmpty($fromCommitId) -or [string]::IsNullOrEmpty($toCommitId)) {
        return
    }

    $formattedUrl = "$($URL)searchCriteria.fromCommitId=$($fromCommitId)&searchCriteria.toCommitId=$($toCommitId)&$($queryString)"
    Write-Host "Commit Id Range filtered url $($formattedUrl)"
    return $formattedUrl    
}
#endregion Request Processing

#region Process Request
function InvokeGetRequest ($URL, $contentType) {    
    try {
        $response = Invoke-RestMethod `
            -Uri $URL `
            -Method $method `
            -ContentType $contentType `
            -Headers $header 
        return $response   
    }
    catch {
        Write-Host $_.ErrorDetails.Message -ErrorAction SilentlyContinue
        Write-Host $_ -ErrorAction SilentlyContinue
    }
}
#endregion Process Request

#region Retrieve filtered results

# result processing
# Construct the download URL
function DownloadContents($filePath) {
    $url = "$($orgUrl)/$project/_apis/git/repositories/$repositoryName/items?path=$filePath&download=true&$queryString"
    $contentType = "application/text"

    $loc = "$Path/$filePath"
    if ([string]::IsNullOrEmpty([IO.Path]::GetExtension((Split-Path $loc -leaf)))) {
        createDirectory $loc
    }

    Write-Host "Downloading contents from $url to $loc"
    if (!(Test-Path -Path $loc -PathType Container)) {
        InvokeGetRequest $url $contentType | Out-File $loc
    }
}

function RetrieveFilteredResults() {
    $dateRangeFilterUrl = CreateDateRangeFilterUrl -URL $url -fromDate $fromDate -toDate $toDate
    $commitIdRangeFilterUrl = CreateCommitIdRangeFilter -URL $url -fromCommitId $fromCommitId -toCommitId $toCommitId
    # Result is populated in browser with the above url
    InvokeGetRequest $dateRangeFilterUrl
    $filteredRange = InvokeGetRequest $commitIdRangeFilterUrl $contentType
    Write-Host "Total filtered results received from the commit range from $fromCommitId to $toCommitId are $($filteredRange.count)"
    $filteredRange | ConvertTo-Json | Out-File $filteredRangeFilePath

    $commitIds = [System.Collections.ArrayList]@()
    foreach ($id in $filteredRange.value) {
        $commitIds.Add($id.commitId)
    }

    $filePaths = [System.Collections.ArrayList]@()
    foreach ($commitId in $commitIds) {
        $newUrl = "$($orgUrl)/$project/_apis/git/repositories/$repositoryId/commits/$commitId/changes?$queryString"
        $filteredCommitData = InvokeGetRequest $newUrl $contentType

        foreach ($item in $filteredCommitData.changes) {
            $filePaths.Add($item.item.path)
        }
    }

    foreach ($filePath in $filePaths) {
        DownloadContents -filePath $filePath
        Start-Sleep 1
    }
}

