# Espi Hunter Tools

A Hunter addon for World of Warcraft: Forever 1.60.1.

- **Pet status.** In combat, the addon warns when your pet is dead or missing. Missing-pet alerts start after you learn Call Pet.
- **Pet happiness.** A living, summoned pet at yellow (Content) or red (Unhappy) triggers a feeding reminder in and out of combat. The reminder clears when the game reports green (Happy).
- **Aspect of the Cheetah.** The addon warns if Cheetah is active when combat starts or if you turn it on during combat. If the client withholds the aura state, the alert asks you to check your buff bar. Dropping the aspect takes a player action.

## Install

Extract the `EspiHunterTools` folder directly into the Forever client's `Interface/AddOns` folder, usually under `World of Warcraft/_forever_`. Verify that `Interface/AddOns/EspiHunterTools/EspiHunterTools.toc` exists, then restart the client and enable **Espi Hunter Tools** from the character selection AddOns menu. Alerts appear above the center of the screen.

## Commands

Type `/espihunter` (or `/eht`) in chat.

- `unlock` / `lock`: show the alert so you can drag it, then lock it in place.
- `scale <0.5-2>`: resize the alert.
- `sound on|off`: play a sound when a new warning appears. Off by default.
- `reset`: restore the default position, scale and sound setting.

Alerts are hidden while you are dead, on a flight path or in a vehicle.

## Feedback and support

Request a feature or report a bug on the [Discord server](https://discord.gg/6QXzmaSjW).

## Donate

Donations are optional and appreciated. Bitcoin (BTC) address:

```text
bc1q3742790fs0xe93nlcj3e4ta5m0fenykkt5euqq
```

## Cheetah keybind

Create a macro with `/macro` and use it in place of the regular Cheetah action-bar button. Press it out of combat to turn Cheetah on. Press it in combat to remove Cheetah if active. Use the spell's localized name on non-English clients.

```text
#showtooltip Aspect of the Cheetah
/cancelaura [combat] Aspect of the Cheetah
/cast [nocombat] !Aspect of the Cheetah
```

## Before uploading to CurseForge

On a Hunter who knows Call Pet and Aspect of the Cheetah, check these in the live Forever client.

1. Enter combat without a summoned pet. Summon a healthy green pet and check that the missing-pet warning clears. If the pet dies, check for the death warning and verify it clears on revive or combat exit.
2. With a living pet at yellow or red happiness, check for a feeding reminder. Feed it until the default pet indicator turns green and check that the alert clears.
3. Enter combat with Cheetah already active. Press the macro in combat and check that the buff drops. Leave combat, then start a fresh fight with Cheetah off and press the macro to confirm it stays off. Try the alert outdoors and in an instance to check how aura restrictions affect it.

Upload `EspiHunterTools-0.1.0.zip` as a **Beta** file for **World of Warcraft → Forever → 1.60.1** in the CurseForge author dashboard after the live checks pass. The archive includes the addon's Lua source and manifest. [CurseForge submission guide](https://support.curseforge.com/support/solutions/articles/9000197241)
