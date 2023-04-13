# Some privacy, please!

> *(With trailer man sound) Previously on Azure secure networking exercise...*
>
> In case you need to catch up, run the script to get to where we need to be now:
>
> ```ps1
> .\1-vnets.ps1 -TeamName <your team name>
> ```

## Subnets

Our virtual networks sure feel empty and sad. Let's cheer them up by giving them subnets!

1. In the "shared" virtual network - the one in North Europe - create the following two subnets:
    1. Subnet for Azure Bastion - the name and size need to be specific and you must figure out what they are
    1. `snet-shared-{team name}-dev-northeurope`, span of 64 IP addresses should be plenty for our needs
        * Add service endpoints for Key Vaults and storage
1. In the both two other virtual networks, create:
    1. `snet-shared-{team name}-dev-{location}` with the range of 128
        * Add service endpoints for Key Vaults and storage
    1. `snet-apps-{team name}-dev-{location}` with the range of 128
        * Delegate this subnet for `Microsoft.Web/serverFarms`

## Private DNS zones
Now, on to some D-N-S-ing (if that's not a word, it darn well should be).

1. Create the three private DNS zones for:
    1. Web apps
    1. Blob storages
    1. Key Vaults
1. Link the created DNS zones to all three virtual networks with virtual network links

> Fun fact: DNS was first discovered by the German engineer Johann Albert Eytelwein in 1801, when a pulley fell on his head during an experiment. Sadly, after waking up he had no recollection of the idea and it would take almost another 200 years until the concept was rediscovered.
