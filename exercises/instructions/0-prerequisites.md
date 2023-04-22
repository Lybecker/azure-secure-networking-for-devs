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

1. Run the script to provision resources

    PowerShell:

    ```ps1
    .\0-prerequisites.ps1 -TeamName <your team name>
    ```

    Bash:

    ```bash
    ./0-prerequisites.sh <your team name>
    ```

    > Make sure your working directory is `scripts` when running the script. This is because the web app code package to deploy is referenced using a relative path.
    >
    > Team name should be given as lower case alphanumeric characters with the maximum length of 10.
    >
    > There are three locations (regions) we will be using during the exercises as described in the table below:
    >
    > | Regions | Parameter/variable in scripts | Default location |
    > | ------- | -------------------- | ---------------- |
    > | EU | `PrimaryLocation` | West Europe (`westeurope`) |
    > | US | `SecondaryLocation` | East US (`eastus`) |
    > | Shared | `SharedLocation` | Sweden central (`swedencentral`)
    >
    > If you want to change any of the default locations, provide the values as parameters, when running the scripts.

    If all goes well, you should now have the [resources](#resources) deployed including the code for the web apps.

1. Test the web apps and generate blobs:
    1. In your browser, navigate to the web app in West Europe: `https://app-<your team name>-dev-eu.azurewebsites.net/`
    1. Generate blobs: `https://app-<your team name>-dev-eu.azurewebsites.net/create_blobs`
    1. List blobs: `https://app-<your team name>-dev-eu.azurewebsites.net/list_blobs`
    1. Repeat the steps for the app service in East US

## Resources

Resources created in resource group "`rg-{team name}-dev`":

| Resource type | Resource name | Default location |
| ------------- | ------------- | ---------------- |
| Storage account | `st{team name}deveu` | West Europe |
| Storage account | `st{team name}devus` | East US |
| Storage account | `stshared{team name}dev` | Sweden central |
| App service plan (Linux) | `plan-{team name}-dev-eu` | West Europe |
| App service plan (Linux) | `plan-{team name}-dev-us` | East US |
| Web app service | `app-{team name}-dev-eu` | West Europe |
| Web app service | `app-{team name}-dev-us` | East US |

## Naming is hard

Links to help with naming resources (these will be useful later):

* [Abbreviation examples for Azure resources](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)
* [Naming rules and restrictions for Azure resources](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-name-rules)