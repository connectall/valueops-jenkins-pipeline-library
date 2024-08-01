# ConnectAll & Insights Jenkins Shared Library

## Methods

### postDeployAndCommitsToInsights
#### Job Parameters

##### ApiKey
The Insights API Key.

##### ApiUrl
The Insights API Base URL. (e.g. https://rally1.rallydev.com)

##### BuildFinishTime (optional)
The time the build completed in milliseconds. (e.g. 1722459117000)

No default is provided.

##### BuildId (optional)
The ID of the build or artifact associated with this deploy. (e.g. insights-deploy-2)

Defaults to `currentBuild.id`.

##### BuildIsSuccessful (optional)
A boolean that indicates whether or not the build was successful.

No default is provided.

##### BuildStartTime
The time the build started in milliseconds. (e.g. 1722459117000)

##### ComponentName
The Name of the VSMComponent the created VSMDeploy is for. (e.g. web-ui)

##### CurrentBuildCommit (optional)
The commit SHA being deployed. (e.g. f75ca53d2b9acf93109e1e52e156f8a1a875e899)

Defaults to `env.GIT_COMMIT`.

##### GitRepoLoc (optional)
The location of the git repo to generate a list of changes from.

Defaults to the current working directory.

##### PreviousSuccessBuildCommit
The commit SHA that was last successfully built and deployed (e.g. f75ca53d2b9acf93109e1e52e156f8a1a875e899)

Defaults to `env.GIT_PREVIOUS_SUCCESSFUL_COMMIT`.

##### WorkspaceObjectId
The Insights Workspace ObjectID. (e.g. 41529001)

### updateDeployToInsights
#### Job Parameters

##### ApiKey
The Insights API Key

##### ApiUrl
The Insights API Base URL. (e.g. https://rally1.rallydev.com)

##### BuildFinishTime
The time the build the finished in milliseconds. (e.g. 1722459117000)

##### BuildId
The ID of the build or artifact associated with this deploy. (e.g. insights-deploy-2)

This ID is used to look up the VSMDeploy that is being updated.

##### BuildIsSuccessful
A boolean that indicates whether or not the build was successful.

##### WorkspaceObjectId
The Insights Workspace ObjectID. (e.g. 41529001)

## Examples

See [examples/jenkins/Insights_Jenkinsfile](./examples/jenkins/Insights_Jenkinsfile) for an example of how to import and call the functions that integrate directly with ValueOps Insights, which are provided by the shared library.