# ######################## Logging functions ########################

function Debug-Log {
    param (
        [string]$Message
    )
    if ($env:DEBUG_VALUEOPS_INSIGHTS_LIBRARY -eq "true") {
        Write-Output "DEBUG: $Message"
    }
}

function Info-Log {
    param (
        [string]$Message
    )
    Write-Output "INFO: $Message"
}

function Error-Log {
    param (
        [string]$Message
    )
    Write-Output "ERROR: $Message"
}

function Exit-WithError {
    param (
        [string]$Message
    )
    Write-Output "ERROR: $Message"
    exit 1
}

# ######################## Helper functions ########################

function Validate-Input {
    param (
        [string]$Value,
        [string]$Name
    )
   # if ([string]::IsNullOrEmpty($Value)) {
   #     Exit-WithError "$Name is not set"
   # }

    if (-not $Value) {
        Exit-WithError "$Name is not set"
    }
}

function Parse-Millis {
    param (
        [string]$ms
    )
    $seconds = [math]::Floor($ms / 1000)
    return (Get-Date -Date (Get-Date "1970-01-01 00:00:00Z").AddSeconds($seconds) -Format "yyyy-MM-ddTHH:mm:ssZ")
}

function Parse-CommitLogTimestamp {
    param (
        [string]$timestamp
    )
    return (Get-Date -Date $timestamp -Format "yyyy-MM-ddTHH:mm:ssZ")
}

function Create-CommitLog {
    param (
        [string]$git_repo_loc,
        [string]$log_path,
        [string]$from_commit,
        [string]$to_commit
    )
    
    git --git-dir="$git_repo_loc/.git" log --pretty=format:'%H %ad' --date=iso $from_commit..$to_commit > $log_path
    #git --git-dir="./.git" log --pretty=format:'%H %ad' --date=iso "HEAD~2".."HEAD" > ./commit_log
}

# ################### ValueOps Insights functions ####################

function Query-Component {
    param (
        [string]$name
    )
    $Resource_Endpoint="$INSIGHTS_API_URI/vsmcomponent?query=(Name%20=%20$name)&workspace=workspace/$API_WORKSPACE_OID&fetch=ObjectID"
    
    $response = Invoke-RestMethod -Uri "$Resource_Endpoint" -Headers @{
        "ZSESSIONID" = $API_KEY
    }

    if (-not $?) {
        Exit-WithError "Could not connect to $API_URL"
    }

    return $response
}

function Get-ComponentObjectId {
    param (
        [PSObject]$response
    )
    return $response | Select-Object -ExpandProperty QueryResult | select-Object -ExpandProperty Results | Select-Object -ExpandProperty ObjectID
}


function Make-VsmDeploy {
    param (
        [string]$deploy_is_successful,
        [string]$formatted_start_date,
        [string]$formatted_end_date,
        [string]$deploy_main_revision,
        [string]$deploy_component_oid,
        [string]$deploy_build_id
    )

    # Set time deployed if formatted_end_date is not null or not empty
    if (-not $formatted_end_date) {
        $formatted_end_date = $null
    }

   $json = @{
        VSMDeploy = @{
            #IsSuccessful = $deploy_is_successful
            #TimeDeployed = $formatted_end_date
            TimeCreated = $formatted_start_date
            MainRevision = $deploy_main_revision
            Component = "vsmcomponent/$deploy_component_oid"
            BuildId = $deploy_build_id
        }
    } | ConvertTo-Json

    $Resource_Endpoint="$INSIGHTS_API_URI/vsmdeploy/create?workspace=workspace/$API_WORKSPACE_OID"
    
    $response = Invoke-RestMethod -Uri "$Resource_Endpoint" -Method Post -Headers @{
        "ZSESSIONID" = $API_KEY
        "Content-Type" = "application/json"
    } -Body $json

    if (-not $?) {
        Exit-WithError "Could not connect to $API_URL"
    }

    return $response
}

function Get-DeployObjectId {
    param (
        [PSObject]$response
    )
    return $response | Select-Object -ExpandProperty CreateResult | Select-Object -ExpandProperty Object | Select-Object -ExpandProperty ObjectID
}

function Make-VsmChange {
    param (
        [string]$commit_id,
        [string]$timestamp,
        [string]$deploy_id
    )
    $json = @{
        VSMChange = @{
            Revision = $commit_id
            CommitTime = $timestamp
            Deploy = $deploy_id
        }
    } | ConvertTo-Json

    $Resource_Endpoint="$INSIGHTS_API_URI/vsmchange/create?workspace=workspace/$API_WORKSPACE_OID"

    $response = Invoke-RestMethod -Uri "$Resource_Endpoint" -Method Post -Headers @{
        "ZSESSIONID" = $API_KEY
        "Content-Type" = "application/json"
    } -Body $json

    if (-not $?) {
        Exit-WithError "Could not connect to $API_URL"
    }

    return $response
}

function Get-ChangeObjectId {
    param (
        [PSObject]$response
    )
    return $response | Select-Object -ExpandProperty CreateResult | Select-Object -ExpandProperty Object | Select-Object -ExpandProperty ObjectID
}




# ######################## Script flow ########################

# Set environment variables
$API_KEY = $env:API_KEY
$API_URL = $env:API_URL
$API_WORKSPACE_OID = $env:API_WORKSPACE_OID
$DEPLOY_COMPONENT_NAME = $env:DEPLOY_COMPONENT_NAME
$DEPLOY_BUILD_ID = $env:DEPLOY_BUILD_ID
$DEPLOY_START_TIME = $env:DEPLOY_START_TIME
$DEPLOY_END_TIME = $env:DEPLOY_END_TIME
$DEPLOY_IS_SUCCESSFUL = $env:DEPLOY_IS_SUCCESSFUL
$DEPLOY_MAIN_REVISION = $env:DEPLOY_MAIN_REVISION
$PREVIOUS_SUCCESS_BUILD_COMMIT = $env:PREVIOUS_SUCCESS_BUILD_COMMIT
$CURRENT_BUILD_COMMIT = $env:CURRENT_BUILD_COMMIT
$GIT_REPO_LOC = $env:GIT_REPO_LOC


Info-Log "Posting Deploy to ValueOps Insights with Build ID: $DEPLOY_BUILD_ID"

Debug-Log "API_URL: $API_URL"
Debug-Log "API_WORKSPACE_OID: $API_WORKSPACE_OID"
Debug-Log "DEPLOY_COMPONENT_NAME: $DEPLOY_COMPONENT_NAME"
Debug-Log "DEPLOY_BUILD_ID: $DEPLOY_BUILD_ID"
Debug-Log "DEPLOY_START_TIME: $DEPLOY_START_TIME"
Debug-Log "DEPLOY_END_TIME: $DEPLOY_END_TIME"
Debug-Log "DEPLOY_IS_SUCCESSFUL: $DEPLOY_IS_SUCCESSFUL"
Debug-Log "DEPLOY_MAIN_REVISION: $DEPLOY_MAIN_REVISION"
Debug-Log "PREVIOUS_SUCCESS_BUILD_COMMIT: $PREVIOUS_SUCCESS_BUILD_COMMIT"
Debug-Log "CURRENT_BUILD_COMMIT: $CURRENT_BUILD_COMMIT"
Debug-Log "GIT_REPO_LOC: $GIT_REPO_LOC"

# Validate input variables
Validate-Input $API_KEY "ApiKey"
Validate-Input $API_URL "ApiUrl"
Validate-Input $API_WORKSPACE_OID "WorkspaceOid"
Validate-Input $DEPLOY_COMPONENT_NAME "ComponentName"
Validate-Input $DEPLOY_BUILD_ID "BuildId"
Validate-Input $DEPLOY_START_TIME "BuildStartTime"
Validate-Input $DEPLOY_MAIN_REVISION "CurrentBuildCommit"
Validate-Input $PREVIOUS_SUCCESS_BUILD_COMMIT "PreviousSuccessBuildCommit"
Validate-Input $CURRENT_BUILD_COMMIT "CurrentBuildCommit"
Validate-Input $GIT_REPO_LOC "GitRepoLoc"



$INSIGHTS_API_URI = "$API_URL/slm/webservice/v2.0"

# Format the Build Start Date
$formatted_start_date = Parse-Millis $DEPLOY_START_TIME
if (-not $?) {
    Exit-WithError "Could not parse start time: $DEPLOY_START_TIME"
}

# Format the Build End Date if it exists
if (-not $DEPLOY_END_TIME -or $DEPLOY_END_TIME -eq "null") {
    $formatted_end_date = $null
} else {
    $formatted_end_date = Parse-Millis $DEPLOY_END_TIME
    if (-not $?) {
        Exit-WithError "Could not parse end time: $DEPLOY_END_TIME"
    }
}

# Find the component by name
$component_response = Query-Component $DEPLOY_COMPONENT_NAME
if (-not $?) {
    Exit-WithError "Failed to query component in Insights"
}

#Debug-Log "Response : $component_response"
#Debug-Log "Response Type : $component_response.GetType().Name"
#$component_response | Select-Object -ExpandProperty QueryResult | select-Object -ExpandProperty Results | Select-Object -ExpandProperty ObjectID

$component_id = Get-ComponentObjectId $component_response
if (-not $component_id) {
    Debug-Log $component_response
    Exit-WithError "Failed to find component in Insights, no component id found in response."
}

Info-Log "Component found in Insights. VSMComponent.ObjectId: $($component_id)"

# Make a Deploy
$deploy_response = Make-VsmDeploy $DEPLOY_IS_SUCCESSFUL $formatted_start_date $formatted_end_date $DEPLOY_MAIN_REVISION $component_id $DEPLOY_BUILD_ID
if (-not $?) {
    Info-Log "VSMDeploy creation failed with response:  $deploy_response"
    Exit-WithError "Failed to create deploy in Insights"
}

Debug-Log "Response : $deploy_response"
Debug-Log "Response CreateResult : $($deploy_response.CreateResult)"
Debug-Log "Response Error : $($deploy_response.CreateResult.Errors)"

$deploy_response | Select-Object -ExpandProperty CreateResult 

# Get Deploy ID
$deploy_id = Get-DeployObjectId $deploy_response
# Exit if we can't find the deploy id in the response (this could be for many reasons)
if (-not $deploy_id) {
    Error-Log "Failed to create deploy in Insights with response: $deploy_response"
    Exit-WithError "Failed to create deploy in Insights, no deploy id found in response"
}
Info-Log "Deploy created successfully. VSMDeploy.ObjectId: $deploy_id"


# Create the commit log we're going to loop over
$log_file_path = "$GIT_REPO_LOC/commit_log"
$git_commit_string = "$PREVIOUS_SUCCESS_BUILD_COMMIT..$CURRENT_BUILD_COMMIT"

Debug-Log "Creating commit log for commits: $git_commit_string"
Debug-Log "Commit contents : $(git --git-dir="$GIT_REPO_LOC/.git" log --pretty=format:'%H %ad' --date=iso $git_commit_string)"


#Create-CommitLog $GIT_REPO_LOC $log_file_path $PREVIOUS_SUCCESS_BUILD_COMMIT $CURRENT_BUILD_COMMIT
rm $log_file_path -ErrorAction SilentlyContinue
git --git-dir="$GIT_REPO_LOC/.git" log --pretty=format:'%H %ad' --date=iso $git_commit_string > $log_file_path

Debug-Log "Commit log created successfully"
Debug-Log "Commit log Contents: $(Get-Content $log_file_path)"

# Loop over the commit log and make VSMChanges
Get-Content $log_file_path | ForEach-Object {
    $line = $_
    $parts = $line -split ' '
    $commit_id = $parts[0]
    $timestamp = $parts[1..($parts.Length - 1)] -join ' '

    Debug-Log "Parsing commit log line: $line"
    # Continue to the next commit if we can't parse the commit id or timestamp
    if (-not $commit_id -or -not $timestamp) {
        Error-Log "Failed to parse commit log line: $line"
        return
    }

    # Parse the date
    $formatted_date = Parse-CommitLogTimestamp $timestamp

    # Make the VSMChange
    Debug-Log "Creating VSMChange for commit: $commit_id with revision time: $formatted_date"
    $change_response = Make-VsmChange $commit_id $formatted_date $deploy_id
    if (-not $?) {
        Info-Log "VSMChange creation failed with response:  $change_response"
        Error-Log "Failed to create VSMChange in Insights"
    }

    Debug-Log "Response : $change_response"
    Debug-Log "Response CreateResult : $($change_response.CreateResult)"
    Debug-Log "Response Error : $($change_response.CreateResult.Errors)"
    # Try to extract the change id
    $change_id = Get-ChangeObjectId $change_response

    # Exit if we can't find the change id in the response (this could be for many reasons)
    if (-not $change_id) {
        Exit-WithError "Failed to create VSMChange in Insights, no change id found in response: $change_response"
    }

    Debug-Log "VSMChange created successfully"
    Debug-Log "VSMChange.ObjectId: $change_id"
}

Info-Log "Deploy and Changes posted successfully to ValueOps Insights with Build ID: $DEPLOY_BUILD_ID"