# Virtual networks

Let's start simple. Your mission, should you accept it, is to create three virtual networks. These virtual networks will form a network boundary around the Azure resource assigned to them, allowing you to control all traffic to and from.

Each one should span 1024 IP addresses with first virtual network starting from IP address `10.0.0.0`. Have the address spaces of all the virtual networks adjacent i.e, to be next to each other i.e., no empty space between the address spaces.

The recommended order and names below:

1. `vnet-{team name}-dev-{hub location}` in the hub location (region) (starting from 10.0.0.0) e.g., `vnet-crzycatseyes-dev-swedencentral`
1. `vnet-{team name}-dev-{EU location}` in EU
1. `vnet-{team name}-dev-{US location}` in US

If you have time left over, debate the existentialism of virtual networks. Are they real? Am I?

## Status check

The current state of affairs should look something like this:

```mermaid
graph
    subgraph rg-hub["rg-hub-{team name}-dev"]
        st-hub("sthub{team name}dev")
        vnet-hub("vnet-{team name}-dev-{hub location}")
    end
    subgraph rg-eu["rg-{team name}-dev-eu"]
        direction TB

        asp-eu("asp-{team name}-dev-eu")
        app-eu("app-{team name}-dev-eu")
        st-eu("st{team name}deveu")

        vnet-eu("vnet-{team name}-dev-{EU location}")

        asp-eu---app-eu
        app-eu-- Storage Blob Data Contributor -->st-hub
        app-eu-- Storage Blob Data Contributor -->st-eu
    end
    subgraph rg-us["rg-{team name}-dev-us"]
        direction TB

        asp-us("asp-{team name}-dev-us")
        app-us("app-{team name}-dev-us")
        st-us("st{team name}devus")

        vnet-us("vnet-{team name}-dev-{US location}")

        asp-us---app-us
        app-us-- Storage Blob Data Contributor -->st-hub
        app-us-- Storage Blob Data Contributor -->st-us
    end
```
