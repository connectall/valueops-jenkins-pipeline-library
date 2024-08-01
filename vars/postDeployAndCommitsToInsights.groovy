def call(Map config = [:]) {
    withEnv([
        "API_KEY=${config.ApiKey}",
        "API_URL=${config.ApiUrl}",
        "API_WORKSPACE_OID=${config.WorkspaceOid}",
        "CURRENT_BUILD_COMMIT=${config.CurrentBuildCommit}",
        "DEPLOY_BUILD_ID=${config.BuildId}",
        "DEPLOY_COMPONENT_NAME=${config.ComponentName}",
        "DEPLOY_END_TIME=${config.BuildFinishTime}",
        "DEPLOY_IS_SUCCESSFUL=${config.BuildIsSuccessful}",
        "DEPLOY_MAIN_REVISION=${config.CurrentBuildCommit || env.GIT_COMMIT}",
        "DEPLOY_START_TIME=${config.BuildStartTime}",
        "GIT_REPO_LOC=${config.GitRepoLoc}",
        "PREVIOUS_SUCCESS_BUILD_COMMIT=${config.PreviousSuccessBuildCommit || env.GIT_PREVIOUS_SUCCESSFUL_COMMIT}"
    ]) {
        sh(libraryResource('postDeployAndCommitsToInsights.sh'))
    }
}