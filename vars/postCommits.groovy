def call(Map config = [:]){
    sh "touch ${config.GitRepoLoc}/commit_log"
    sh "git --git-dir=${config.GitRepoLoc}/.git log --pretty=format:'%H %ad' --date=iso ${config.PrevSuccessBuildCommit}..${config.CurrentBuildCommit} > ${config.GitRepoLoc}/commit_log"
    sh "echo >> ${config.GitRepoLoc}/commit_log"
    sh "cat ${config.GitRepoLoc}/commit_log"
    sh """#!/bin/bash
    _AUTOMATION_NAME="${config.AutomationName}"
    _DEPLOY_ID="${config.DeployId}"

    _GIT_REPO_LOC="${config.GitRepoLoc}"
    
    _CONNECTALL_UA_URL=${config.ConnectALL_Api_Url}
    _CONNECTALL_API_KEY=${config.ConnectALL_Api_Key}
    
    echo "Automation Name: \$_AUTOMATION_NAME"
    echo "Deploy ID: \$_DEPLOY_ID"

    # Reading each line from the file
    while IFS= read -r input_text; do
        # Splitting the input text by space to separate commit ID and timestamp
        read -r commit_id timestamp <<< \$input_text

        formatted_date=\$(date -d \"\$timestamp\" +'%Y-%m-%dT%H:%M:%S%z')
        #formatted_date=\$(date -j -f '%Y-%m-%d %H:%M:%S %z' '\$timestamp' +'%Y-%m-%dT%H:%M:%S%z')

        json="{&quot;appLinkName&quot;:&quot;\$_AUTOMATION_NAME&quot;,&quot;fields&quot;: {&quot;CommitId&quot;:&quot;\$commit_id&quot;,&quot;CommitTimestamp&quot;:&quot;\$formatted_date&quot;,&quot;DeployId&quot;: &quot;\$_DEPLOY_ID&quot;}}"
        json_str=\$(echo \$json | sed 's/&quot;/"/g')
        
        echo "Json : \$json"
        echo "Json_Formatted : \$json_str"
        # Post to connectall
        curl --header 'Content-Type: application/json;charset=UTF-8' -X POST -d \"\$json_str\" \$_CONNECTALL_UA_URL/connectall/api/2/postRecord?apikey=\$_CONNECTALL_API_KEY
    done < "\$_GIT_REPO_LOC/commit_log"
    
    """
    sh "echo Completed"
}   