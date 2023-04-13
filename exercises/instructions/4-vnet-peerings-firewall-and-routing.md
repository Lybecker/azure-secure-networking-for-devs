# Cells interlinked

> That Bastion stuff wasn't that bad, was it? But in case you were playing Solitare the entire time, here you go:
>
> ```ps1
> .\3-bastion-jumpbox.ps1 -TeamName <your team name>
> ```

## Virtual network peering

Our virtual networks are like galaxies. Systems of cells interlinked within cells interlinked. *Cells interlinked*. Drifting away in the empty vastness of silent space. In solitude, forever to travel alone until the last dark star shines its last light.

<!-- markdownlint-disable MD033 -->
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Against the dark, a tall white fountain played.<p>...</p>
<!-- markdownlint-enable MD033 -->

Right... It's kinda important for our case that the virtual networks are connected. In order to do that we need to peer them using a hub and spoke model. Enough talking, let's get to it: Peer the virtual networks so that the one in North Europe acts as the hub. What are you waiting for? Go! Execute!
