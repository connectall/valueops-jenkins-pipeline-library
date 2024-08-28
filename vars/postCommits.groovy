def call(Map config = [:]){
    def defaultConfig = [
        ApiKey: '',
        ApiUrl: '',
        BuildId: currentBuild.id,
        GitRepoLoc: './',
        CurrentBuildCommit: env.GIT_COMMIT ?: '',
        PrevSuccessBuildCommit: env.GIT_PREVIOUS_SUCCESSFUL_COMMIT ?: ''
    ]
    def mergedConfig = defaultConfig + config

    withEnv([
        "API_KEY=${mergedConfig.ConnectALL_Api_Key}",
        "API_URL=${mergedConfig.ConnectALL_Api_Url}",
        "AUTOMATION_NAME=${mergedConfig.AutomationName}",
        "DEPLOY_BUILD_ID=${mergedConfig.DeployId}",
        "GIT_REPO_LOC=${mergedConfig.GitRepoLoc}",
        "CURRENT_BUILD_COMMIT=${mergedConfig.CurrentBuildCommit}",
        "PREVIOUS_SUCCESS_BUILD_COMMIT=${mergedConfig.PrevSuccessBuildCommit}"
    ]) {
        sh(libraryResource('postCommitsUsingConnectALL.sh'))
    }
}
