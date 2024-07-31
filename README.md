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
##### BuildId
The ID of the build or artifact associated with this deploy. (e.g. insights-deploy-2)
##### BuildIsSuccessful (optional)
A boolean that indicates whether or not the build was successful.
##### BuildStartTime
The time the build started in milliseconds. (e.g. 1722459117000)
##### ComponentObjectId
The ObjectID of the VSMComponent the created VSMDeploy is for. (e.g. 423575325641)
##### CurrentBuildCommit
The commit SHA being built and deploye. (e.g. f75ca53d2b9acf93109e1e52e156f8a1a875e899)
##### WorkspaceObjectId
The Insights Workspace ObjectID. (e.g. 41529001)
##### PreviousSuccessBuildCommit
The commit SHA that was last successfully built and deployed (e.g. f75ca53d2b9acf93109e1e52e156f8a1a875e899)

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