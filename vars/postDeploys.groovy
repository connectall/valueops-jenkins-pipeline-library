def call(Map config = [:]){
    defaultConfig = [
        BuildId: currentBuild.id,
        BuildStartTime: '',
        BuildFinishTime: '',
        BuildCommit: '',
        BuildResult: 'false'
    ]

    mergedConfig = defaultConfig + config

    withEnv([
      "API_KEY=${mergedConfig.ConnectALL_Api_Key}",
      "API_URL=${mergedConfig.ConnectALL_Api_Url}",
      "AUTOMATION_NAME=${mergedConfig.AutomationName}",
      "DEPLOY_COMPONENT=${mergedConfig.BuildComponent}",
      "DEPLOY_BUILD_ID=${mergedConfig.DeployId}",
      "DEPLOY_START_TIME=${mergedConfig.BuildStartTime}",
      "DEPLOY_END_TIME=${mergedConfig.BuildFinishTime}",
      "DEPLOY_IS_SUCCESSFUL=${mergedConfig.BuildResult}",
      "DEPLOY_MAIN_REVISION=${mergedConfig.BuildCommit}"
  ]) {
        sh(libraryResource('postDeployUsingConnectALL.sh'))
  }
}
