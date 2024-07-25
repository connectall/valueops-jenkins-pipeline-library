def call(Map config = [:]){
    sh """
    #!/bin/bash

    
    _AUTOMATION_NAME=${config.AutomationName}
    
    _DEPLOY_ID=${config.DeployId}
    _IS_SUCCESSFUL=${config.BuildResult}
    
    _BUILD_COMPONENT=${config.BuildComponent}
    _BUILD_START_TIME=${config.BuildStartTime}
    _BUILD_END_TIME=${config.BuildFinishTime}
    
    _CONNECTALL_UA_URL=${config.ConnectALL_Api_Url}
    _CONNECTALL_API_KEY=${config.ConnectALL_Api_Key}

    _BUILD_START_TIME_INT=\$((\$_BUILD_START_TIME / 1000))
    _Formatted_Start_Date=\$(date --date=\"@\$_BUILD_START_TIME_INT\" +'%Y-%m-%dT%H:%M:%S%z')
    # _Formatted_Start_Date=\$(date -j -f "%s" "\$_BUILD_START_TIME_INT" +"%Y-%m-%dT%H:%M:%S%z")
    
    _BUILD_END_TIME_INT=\$((\$_BUILD_END_TIME / 1000))
    _Formatted_End_Date=\$(date --date=\"@\$_BUILD_END_TIME_INT\" +'%Y-%m-%dT%H:%M:%S%z')
    

    #echo 'Automation Name : \$_AUTOMATION_NAME'
    json="{&quot;appLinkName&quot;:&quot;\$_AUTOMATION_NAME&quot;,&quot;fields&quot;: {&quot;IsSuccessful&quot;:&quot;\$_IS_SUCCESSFUL&quot;,&quot;TimeCreated&quot;:&quot;\$_Formatted_Start_Date&quot;,&quot;TimeDeployed&quot;:&quot;\$_Formatted_End_Date&quot;,&quot;Component&quot;:&quot;\$_BUILD_COMPONENT&quot;,&quot;Id&quot;: &quot;\$_DEPLOY_ID&quot;}}"

    json_str=\$(echo \$json | sed 's/&quot;/"/g')
    
    echo "Json : \$json"
    echo "Json_Formatted : \$json_str"
    # Post to connectall
    curl --header 'Content-Type: application/json;charset=UTF-8' -X POST -d \"\$json_str\" \$_CONNECTALL_UA_URL/connectall/api/2/postRecord?apikey=\$_CONNECTALL_API_KEY
         
    """
    sh 'echo Completed'
}