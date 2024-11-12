def call(Map config = [:]) {
    def defaultConfig = [
        ApiKey: '',
        ApiUrl: '',
        WorkspaceOid: '',
        CurrentBuildCommit: env.GIT_COMMIT ?: '',
        BuildId: currentBuild.id,
        ComponentName: '',
        BuildFinishTime: '',
        BuildIsSuccessful: '',
        BuildStartTime: '',
        GitRepoLoc: './',
        PreviousSuccessBuildCommit: env.GIT_PREVIOUS_SUCCESSFUL_COMMIT ?: '',
        Runtime: 'Linux'
    ]
    def mergedConfig = defaultConfig + config

    withEnv([
        "API_KEY=${mergedConfig.ApiKey}",
        "API_URL=${mergedConfig.ApiUrl}",
        "API_WORKSPACE_OID=${mergedConfig.WorkspaceOid}",
        "CURRENT_BUILD_COMMIT=${mergedConfig.CurrentBuildCommit}",
        "DEPLOY_BUILD_ID=${mergedConfig.BuildId}",
        "DEPLOY_COMPONENT_NAME=${mergedConfig.ComponentName}",
        "DEPLOY_END_TIME=${mergedConfig.BuildFinishTime}",
        "DEPLOY_IS_SUCCESSFUL=${mergedConfig.BuildIsSuccessful}",
        "DEPLOY_MAIN_REVISION=${mergedConfig.CurrentBuildCommit}",
        "DEPLOY_START_TIME=${mergedConfig.BuildStartTime}",
        "GIT_REPO_LOC=${mergedConfig.GitRepoLoc}",
        "PREVIOUS_SUCCESS_BUILD_COMMIT=${mergedConfig.PreviousSuccessBuildCommit}"
    ]) {
        if (mergedConfig.Runtime == 'Windows') {
            echo 'Running Windows Powershell script'
            powershell(libraryResource('win_postDeployAndCommitsToInsights.ps1'))
        } else if (mergedConfig.Runtime == 'Linux') {
            echo 'Running Linux script'
            sh(libraryResource('postDeployAndCommitsToInsights.sh'))
        } else {
            error 'Runtime not supported'
        }
    }
}
