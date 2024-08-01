def call(Map config = [:]) {
  def defaultConfig = [
    ApiKey: '',
    ApiUrl: '',
    WorkspaceOid: '',
    BuildId: currentBuild.id,
    BuildFinishTime: '',
    BuildIsSuccessful: ''
  ]
  def mergedConfig = defaultConfig + config
  
  withEnv([
      "API_KEY=${mergedConfig.ApiKey}",
      "API_URL=${mergedConfig.ApiUrl}",
      "API_WORKSPACE_OID=${mergedConfig.WorkspaceOid}",
      "DEPLOY_BUILD_ID=${mergedConfig.BuildId}",
      "DEPLOY_END_TIME=${mergedConfig.BuildFinishTime}",
      "DEPLOY_IS_SUCCESSFUL=${mergedConfig.BuildIsSuccessful}"
  ]) {
      sh(libraryResource('updateDeployToInsights.sh'))
  }
}