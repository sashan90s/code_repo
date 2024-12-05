steps:
- task: VSBuild@1
  inputs:
    solution: '**/*.sqlproj'
    msbuildArgs: '/p:Configuration=Release /p:OutputPath=$(Build.ArtifactStagingDirectory)'
    platform: 'Any CPU'
    configuration: 'Release'

- task: CopyFiles@2
  inputs:
    SourceFolder: '$(Build.ArtifactStagingDirectory)'
    Contents: '**/*.dacpac'
    TargetFolder: '$(Build.SourcesDirectory)/Dacpacs'

- script: |
    git config --global user.email "$(GIT_USER)"
    git config --global user.name "Azure DevOps Pipeline"
    git remote set-url origin https://$(GIT_USER):$(GIT_TOKEN)@<repository-url>.git
    git add Dacpacs/*.dacpac
    git commit -m "Update DACPAC file [$(Build.BuildId)]"
    git push
  displayName: "Push changes to repository"











  ----------------------------------------------------------------------------------------
  Sihan's guide on it
  ----------------------------------------------------------------------------------------

1. Create a Personal Access Token (PAT) for Git Authentication
If you're using GitHub, GitLab, or similar, you'll need a Personal Access Token (PAT) for the pipeline to push changes.

a. For Azure Repos
Go to Azure DevOps Profile (top-right corner) > Personal Access Tokens.
Click + New Token:
Set Name (e.g., "Pipeline Token").
Set Scope: Select "Code (Read & Write)".
Set an expiry date.
Generate the token and copy it. Store it securely (e.g., Azure Key Vault).

2. Add the Token or Key to Azure DevOps
a. Go to Pipeline Library
Open Project Settings > Pipelines > Library.

Click + Variable Group to create a new group (e.g., "GitCredentials").

Add variables:

Name: GIT_USER (value: your Git username or bot user email).
Name: GIT_TOKEN (value: your PAT or SSH key passphrase).
Enable the Keep this value secret option for the token.

3. Adding the Azure DevOps Pipeline Bot as a Collaborator
If you're using a service connection or the default pipeline bot, you must explicitly grant it access to the repository.

For Azure Repos (Azure DevOps):
Go to your Azure DevOps project.
Open the repository where you want to push changes.
Navigate to Project Settings > Repositories > Security.
Search for Build Service (e.g., [ProjectName] Build Service).
Assign the Contribute and Contribute to Pull Requests permissions to this account.