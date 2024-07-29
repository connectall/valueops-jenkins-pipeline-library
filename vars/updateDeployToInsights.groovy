def call(Map config = [:]) {
    withEnv([
        "API_KEY=${config.ApiKey}",
        "API_URL=${config.ApiUrl}",
        "API_WORKSPACE_OID=${config.InsightsWorkspaceObjectId}",
        "DEPLOY_BUILD_ID=${config.BuildId}",
        "DEPLOY_END_TIME=${config.BuildFinishTime}",
        "DEPLOY_IS_SUCCESSFUL=${config.BuildIsSuccessful}"
    ]) {
        sh(libraryResource('updateDeployToInsights.sh'))
    }
}