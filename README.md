# VScript-Popfile-Extensions
VScript extensions for use inside population files
Should make embedding VScripts into population files easier

Provides OnSpawn, OnDeath, OnTakeDamage, OnTakeDamagePost, OnDealDamage, OnDealDamagePost hooks to spawned bots with specified Tags

Provides OnSpawn, OnDeath, OnTakeDamage, OnTakeDamagePost hooks to spawned tanks with specified Name

How to install:
put scripts directory inside tf directory, merge if necessary

scripts/population/mvm_bigrock_vscript.pop is a demonstrative popfile that makes use of all available hooks

## Example
The example below makes bots with tag abc green ,and tanks named abc red:
```
        // Add or replace existing InitWaveOutput with code below
        InitWaveOutput
        {
            Target gamerules // gamerules or tf_gamerules, depending on the map
            Action RunScriptCode
            Param "
                // The original InitWaveOutput trigger, change if necessary
                EntFire(`wave_init_relay`, `Trigger`)

                // Load popextensions script
                IncludeScript(`popextensions`)

                // If you are hitting the 4096 character limit inside this script, it would be required to put hooks into separate file
                // IncludeScript(`mypophooks`)
                // Add event hooks for bots with specifed Tag.
                AddRobotTag(`abc`, {
                    // Called when the robot is spawned
                    OnSpawn = function(bot, tag) {
                        ClientPrint(null, 2, `OnSpawn`)
                        bot.KeyValueFromString(`rendercolor`, `0 255 0`)
                    },
                    // Called when the robot is killed
		    // Params as in https://wiki.alliedmods.net/Team_Fortress_2_Events#mvm_tank_destroyed_by_players:~:text=they%20changed%20to-,player_death,-Note%3A%20When
                    OnDeath = function(bot, params) {
                        ClientPrint(null, 2, `OnDeath`)
                        PrintTable(params)
                        // Restore colors back to normal as necessary
                        bot.KeyValueFromString(`rendercolor`, `255 255 255`)
                    },
                })
                // Add event hooks for tanks with specifed Name
                AddTankName(`abc`, {
                    // Called when the tank is spawned
                    OnSpawn = function(tank, name) {
                        ClientPrint(null, 2, `OnSpawnTank`);
                        tank.KeyValueFromString(`rendercolor`, `255 0 0`)
                    },
                })
            "
        }

```
## TODO
Maybe a way to easily create point templates and spawn them on bots, if someone makes it would be welcome
