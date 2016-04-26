### Kamil's Factorio PvP mod

You need to place the contents of this repo in folder `FACTORIO_FOLDER/mods/FfA_mod_VERSION`, where `VERSION` is the version number described in `info.json`, e.g. `/home/kdomanski/factorio-multiplayer/mods/FfA_mod_0.2.0`.

If your multiplayer player's name contains an underscore (`_`) then the text before the underscore will be your force's name. Thus players `devops_john` and `devops_mike` will both be members of a force called `devops`. If your name doesn't contain an underscore then you will be a member of a force named the same as you.

You can tweak the constants `KILL_ALIENS_RANGE` and `TELEPORT_DISTANCE` but if the clients have different values from server's, then they will resynchronize with the sever anyways.
