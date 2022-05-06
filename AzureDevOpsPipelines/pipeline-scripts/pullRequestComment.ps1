using assembly System.Web

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $OrganizationUri,

    [Parameter(Mandatory=$true)]
    [string]
    $Project,

    [Parameter(Mandatory=$true)]
    [string]
    $RepositoryId,

    [Parameter(Mandatory=$true)]
    [string]
    $PullRequestId,

    [Parameter(Mandatory=$true)]
    [string]
    $BuildId,

    [Parameter(Mandatory=$true)]
    [string]
    $PlanOutput
)

try {

    $headers = @{
        Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN"
    }

    $newThreadEndpoint = "$( $OrganizationUri )/$( $Project )/_apis/git/repositories/$( $RepositoryId )/pullRequests/$( $PullRequestId )/threads?api-version=6.0"

    $newThreadEndpoint

    $buildUri = [System.Web.HttpUtility]::UrlPathEncode(("$( $OrganizationUri )$( $Project )/_build/results?buildId=$( $BuildId )&view=logs"))

    $content = "# THIS MUST BE REVIEWED BEFORE MERGE`r`n`r`n`r`n`r`n " + `
                "[Click to navigate to detailed log]($( $buildUri ))`r`n"

    $content += "```````n"
    

    $includeLineSwitch = $false

    foreach ($item in $( $PlanOutput -split "\[NEWLINE\]" ) ) {
        if (-not $includeLineSwitch) {
            $includeLineSwitch = $item -like "*Terraform will perform the following actions:*"
        }
        
        if ($includeLineSwitch) {
            $content += "`r`n$( $item )" 
        }
    }
    
    $content += "`r`n``````"

    $newThread = @{
        Comments = @(
            @{
                ParentCommentId = 0
                Content         = $content
                CommentType     = "text"
            }
        )
        Status = "Active"
    } 

    $newThreadBody = $newThread | ConvertTo-Json -Depth 10

    $newThreadBody 

    $thread = Invoke-RestMethod -Uri $newThreadEndpoint -Headers $headers  -Method Post -Body $newThreadBody -ContentType 'application/json'

    $thread
}
catch {
    Write-Error -Message "Failed to add plan ad PR comment:  $($Error[0])"
}