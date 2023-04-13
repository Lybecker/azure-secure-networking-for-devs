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

    ```ps1
    .\0-prerequisites.ps1 -TeamName <your team name>
    ```

    > Team name should be given as lower case alphanumeric characters with the maximum length of 10.

If all goes well, you should have the following resources deployed into the newly created resource group "`rg-{team name}-dev`":

| Resource type | Resource name | Default location |
| ------------- | ------------- | ---------------- |
| Storage account | `st{team name}deveu` | West Europe |
| Storage account | `st{team name}devus` | East US |
| Storage account | `stshared{team name}dev` | North Europe |
| App service plan (Linux) | `plan-{team name}-dev-eu` | West Europe |
| App service plan (Linux) | `plan-{team name}-dev-us` | East US |
| Web app service | `app-{team name}-dev-eu` | West Europe |
| Web app service | `app-{team name}-dev-us` | East US |

The web apps will also have the code deployed.

*TODO: Navigate to web app to test code deployment.*
