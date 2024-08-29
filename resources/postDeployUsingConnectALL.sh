#!/bin/bash


# ######################## Logging functions ########################

debug() {
  if [ "$DEBUG_VALUEOPS_INSIGHTS_LIBRARY" = "true" ]; then
    echo "DEBUG: $1"
  fi
}

info() {
    echo "INFO: $1"
}

exitWithError() {
    echo "ERROR: $1"
    exit 1
}

# ######################## Helper functions ########################

validate_input() {
  if [ -z "$1" ]; then
    exitWithError "$2 is not set"
  fi
}

parse_millis() {
    local ms=$1
    local seconds=$((ms / 1000))
    local _formatted_date

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        _formatted_date=$(date -r $seconds -u +"%Y-%m-%dT%H:%M:%S%z")
    else
        # Linux and other Unix-like systems
        _formatted_date=$(date -u -d @$seconds +"%Y-%m-%dT%H:%M:%S%z")
    fi

    echo "$_formatted_date"
}

post_Deploy() {
    local _deployId=$1
    local _deployStartDate=$2
    local _deployEndDate=$3
    local _deployCommit=$4
    local _deployComponent=$5
    local _isSuccessful=$6
    local _automationName=$7

    # if CREATE_DEPLOY is true then print creating deploy message
    if [ "$CREATE_DEPLOY" = "true" ]; then
        json="{ 
        \"appLinkName\":\"$_automationName\",
        \"fields\": {
            \"TimeCreated\":\"$_deployStartDate\",
            \"MainRevision\":\"$_deployCommit\",
            \"Component\":\"$_deployComponent\",
            \"Id\": \"$_deployId\"
            }
        }"
    else
        json="{ 
        \"appLinkName\":\"$_automationName\",
        \"fields\": {
            \"IsSuccessful\":\"$_isSuccessful\",
            \"TimeCreated\":\"$_deployStartDate\",
            \"TimeDeployed\":\"$_deployEndDate\",
            \"Component\":\"$_deployComponent\",
            \"Id\": \"$_deployId\"
            }
        }"
    fi

    

    debug "Posting Deploy to ConnectALL"
    debug "$json"

    response=$(curl -s -o /dev/null -X POST -H "Content-Type: application/json;charset=UTF-8" -d "$json" "$API_URL/connectall/api/2/postRecord?apikey=$API_KEY")
    if [ $? -ne 0 ]; then
        exitWithError "Could not connect to $API_URL" 
    fi
    
    debug "$response"
}

# ######################## Main script ########################

info "Posting Deploy to ConnectALL with Build ID: $DEPLOY_BUILD_ID"

debug "API_URL: $API_URL"
debug "AUTOMATION_NAME: $AUTOMATION_NAME"
debug "DEPLOY_BUILD_ID: $DEPLOY_BUILD_ID"
debug "DEPLOY_START_TIME: $DEPLOY_START_TIME"
debug "DEPLOY_END_TIME: $DEPLOY_END_TIME"
debug "DEPLOY_IS_SUCCESSFUL: $DEPLOY_IS_SUCCESSFUL"
debug "DEPLOY_MAIN_REVISION: $DEPLOY_MAIN_REVISION"
debug "DEPLOY_COMPONENT: $DEPLOY_COMPONENT"

# echo "PREVIOUS_SUCCESS_BUILD_COMMIT: $PREVIOUS_SUCCESS_BUILD_COMMIT"
# echo "CURRENT_BUILD_COMMIT: $CURRENT_BUILD_COMMIT"
# echo "GIT_REPO_LOC: $GIT_REPO_LOC"


# Validate input variables
validate_input "$API_KEY" "ConnectALL_Api_Key"
validate_input "$API_URL" "ConnectALL_Api_Url"
validate_input "$AUTOMATION_NAME" "AutomationName"
validate_input "$DEPLOY_BUILD_ID" "DeployId"
validate_input "$DEPLOY_COMPONENT: BuildComponent"
validate_input "$DEPLOY_START_TIME: BuildStartTime"


# Format the start and end date
if [ -n "$DEPLOY_START_TIME" ]; then
    _formatted_start_date=$(parse_millis $DEPLOY_START_TIME)
    if [ $? -ne 0 ]; then
        exitWithError "Could not parse deploy start time: $DEPLOY_START_TIME"
    fi
    debug "Formatted start date: $_formatted_start_date converted from $DEPLOY_START_TIME"
else
    _formatted_start_date=""
fi

if [ -n "$DEPLOY_END_TIME" ]; then
    _formatted_end_date=$(parse_millis $DEPLOY_END_TIME)
    if [ $? -ne 0 ]; then
        exitWithError "Could not parse deploy end time: $DEPLOY_END_TIME"
    fi
     debug "Formatted end date: $_formatted_end_date converted from $DEPLOY_END_TIME"
else
    _formatted_end_date=""
fi

debug "Formatted start date: $_formatted_start_date"
debug "Formatted end date: $_formatted_end_date"


post_Deploy "$DEPLOY_BUILD_ID" "$_formatted_start_date" "$_formatted_end_date" "$DEPLOY_MAIN_REVISION" "$DEPLOY_COMPONENT" "$DEPLOY_IS_SUCCESSFUL" "$AUTOMATION_NAME"
## Exit if error
if [ $? -ne 0 ]; then
    exitWithError "Failed to post deploy to ConnectALL"
fi

info "Deploy posted successfully to ConnectALL with Build ID: $DEPLOY_BUILD_ID"


