# Powershell script uses TFS REST API to find and download changed source files between two points in history of a given Git branch
This script is written in PowerShell and it uses the TFS REST API to find and download changed source files between two points in history of a given Git branch. The script uses the **Invoke-RestMethod** command to make a GET request to the TFS REST API endpoint to retrieve a list of commits that fall within a specified date range or commit ID range. The script then uses the commit details to construct URLs to download the changed files.

The script uses two functions **CreateDateRangeFilterUrl** and **CreateCommitIdRangeFilter** to create the url for GET request that filter the commits based on date range and commit id range respectively.

The script also creates a .zip archive of the downloaded files and uploads the .zip archive to a network share.

It is using Personal access token (PAT) to authenticate the user and defined in $patToken variable.

You will have to replace **$organization** , **$project** , **$repositoryName** , **$repositoryId** , **$patToken** with your organization, project, repository name, repository id and your personal access token respectively.

You can also update the **$fromDate** , **$toDate** , **$fromCommitId** , **$toCommitId** and **$networkPath** with your desired values.

This script should be a good starting point, but it's worth noting that you may have to tweak it to fit your specific use case.
