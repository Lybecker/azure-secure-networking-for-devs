# Warm-up

Let's provision our first resources in Azure!

1. Login to Azure with [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)

    ```ps1
    az login
    ```

1. Make sure you have the desired subscription set and change it if necessary

    ```ps1
    az account show
    ```

    ```ps1
    az account set --subscription <subscription name or ID>
    ```

1. Set environment variables defining the team name and the Azure locations (regions) to use: Edit the environment variables script (`set-env.{ps1|sh}`) to set your values and run it

    PowerShell:

    ```ps1
    .\set-env.ps1
    ```

    Bash:

    ```bash
    . ./set-env.sh
    ```

    > Verify that the variables are set by printing out the team name variable: "`$env:TEAM_NAME`" command in PowerShell and "`echo $TEAM_NAME`" command in Bash.

1. Run the script to provision resources

    PowerShell:

    ```ps1
    .\0-prerequisites.ps1
    ```

    Bash:

    ```bash
    ./0-prerequisites.sh
    ```

    > Make sure your working directory is `scripts` when running the script. This is because the web app code package to deploy is referenced using a relative path.
    >
    > Team name should be given as lower case alphanumeric characters with the maximum length of 10.
    >
    > There are three locations (regions) we will be using during the exercises. The default values shown in the table below:
    >
    > | Region | Environment variable name | Default location |
    > | ------- | ------------------------ | ---------------- |
    > | EU | `EU_LOCATION` | West Europe (`westeurope`) |
    > | US | `US_LOCATION` | East US (`eastus`) |
    > | Hub | `HUB_LOCATION` | Sweden central (`swedencentral`)

    If all goes well, you should now have the [resources](#status-check) deployed including the code for the web apps.

1. Test the web apps and generate blobs:
    1. In your browser, navigate to the web app in the EU region: `https://app-<your team name>-dev-eu.azurewebsites.net/`
    1. Generate blobs: `https://app-<your team name>-dev-eu.azurewebsites.net/create_blobs`
    1. List blobs: `https://app-<your team name>-dev-eu.azurewebsites.net/list_blobs`
    1. Repeat the steps for the app service in the US region

## Status check

We should now have the following resources created:

```mermaid
graph
    subgraph rg-hub["rg-hub-{team name}-dev"]
        st-hub("sthub{team name}dev")
    end
    subgraph rg-eu["rg-{team name}-dev-eu"]
        direction TB

        asp-eu("asp-{team name}-dev-eu")
        app-eu("app-{team name}-dev-eu")
        st-eu("st{team name}deveu")

        asp-eu---app-eu
        app-eu-- Storage Blob Data Contributor -->st-hub
        app-eu-- Storage Blob Data Contributor -->st-eu
    end
    subgraph rg-us["rg-{team name}-dev-us"]
        direction TB

        asp-us("asp-{team name}-dev-us")
        app-us("app-{team name}-dev-us")
        st-us("st{team name}devus")

        asp-us---app-us
        app-us-- Storage Blob Data Contributor -->st-hub
        app-us-- Storage Blob Data Contributor -->st-us
    end
```

| Resource type | Resource name | Resource group | Default location |
| ------------- | ------------- | -------------- | ---------------- |
| Storage account | `sthub{team name}dev` | `rg-hub-{team name}-dev` | Sweden central |
| Storage account | `st{team name}deveu` | `rg-{team name}-dev-eu` | West Europe |
| Storage account | `st{team name}devus` | `rg-{team name}-dev-us` | East US |
| App service plan (Linux) | `asp-{team name}-dev-eu` | `rg-{team name}-dev-eu` | West Europe |
| App service plan (Linux) | `asp-{team name}-dev-us` | `rg-{team name}-dev-us` | East US |
| Web app service | `app-{team name}-dev-eu` | `rg-{team name}-dev-eu` | West Europe |
| Web app service | `app-{team name}-dev-us` | `rg-{team name}-dev-us` | East US |

## Naming is hard

Links to help with naming resources (these will be useful later):

* [Abbreviation examples for Azure resources](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
* [Naming rules and restrictions for Azure resources](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules)