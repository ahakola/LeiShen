# !!! Last update **2013**

# LeiShen

Simple addon to detect and countdown Static Shock or Overcharge on player when fighting Lei Shen in Throne of Thunder. If player can solo soak Static Shock, the addon will announce it to raid instead of counting down. Addons checks if soaking spells and abilities are on CD (and for Forbearance on paladins) before announcing if player can soak solo or not. If player can't soak solo for any reason, addon will do countdown.

All countdowns and announcements will be done via /say but players can change it easily by editing the core.lua row 14. Works on every raidsize and difficulty except LFR.

## Supported soaking spells and abilities:
* Dispersion (shadow priest)
* Cloak of Shadows (rogue)
* Ice Block (mage)
* Zen Meditation (monk)
* Deterrence (hunter)
* Divine Shield (paladin)

## Also following talens and spells are supported if selected:

* Cloak of Shadows (balance druid via Symbiosis)
* Divine Shield (feral druid via Symbiosis)
* Dispersion (feral druid via Symbiosis)
* Deterrence (restoration druid via Symbiosis)
* Ice Block (restoration druid via Symbiosis)
* Sacrificial Pact & Unending Resolve (warlock)
* Cheat Death (rogue)
* Greater Invisibility (mage)
* Diffuse Magic (monk)