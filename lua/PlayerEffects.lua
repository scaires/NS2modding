// ======= Copyright � 2003-2010, Unknown Worlds Entertainment, Inc. All rights reserved. =======
//
// lua\PlayerEffects.lua
//
//    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
//
// ========= For more information, visit us at http://www.unknownworlds.com =====================

/*
Alien.lua:38: Alien.kMetabolizeSmallEffect = PrecacheAsset("cinematics/alien/metabolize_small.cinematic")
Alien.lua:39: Alien.kMetabolizeLargeEffect = PrecacheAsset("cinematics/alien/metabolize_large.cinematic")

Marine.lua:34: Marine.kFlinchEffect = PrecacheAsset("cinematics/marine/hit.cinematic")
Marine.lua:35: Marine.kFlinchBigEffect = PrecacheAsset("cinematics/marine/hit_big.cinematic")
Marine.lua:36: Marine.kSquadSpawnEffect = PrecacheAsset("cinematics/marine/squad_spawn")
Marine.lua:38: Marine.kJetpackEffect = PrecacheAsset("cinematics/marine/jetpack/jet.cinematic")
Marine.lua:39: Marine.kJetpackTrailEffect = PrecacheAsset("cinematics/marine/jetpack/trail.cinematic")
Marine.lua:24: Marine.kDieSoundName = PrecacheAsset("sound/ns2.fev/marine/common/death")
Marine.lua:25: Marine.kFlashlightSoundName = PrecacheAsset("sound/ns2.fev/common/light")
Marine.lua:26: Marine.kGunPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_gun")
Marine.lua:27: Marine.kJetpackPickupSound = PrecacheAsset("sound/ns2.fev/marine/common/pickup_jetpack")
Marine.lua:28: Marine.kSpendPlasmaSoundName = PrecacheAsset("sound/ns2.fev/marine/common/player_spend_nanites")
Marine.lua:29: Marine.kCatalystSound = PrecacheAsset("sound/ns2.fev/marine/common/catalyst")
Marine.lua:30: Marine.kSquadSpawnSound = PrecacheAsset("sound/ns2.fev/marine/common/squad_spawn")
Marine.lua:31: Marine.kChatSound = PrecacheAsset("sound/ns2.fev/marine/common/chat")
Marine.lua:32: Marine.kSoldierLostAlertSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/soldier_lost")
Marine.lua:42: Marine.kJetpackStart = PrecacheAsset("sound/ns2.fev/marine/common/jetpack_start")
Marine.lua:43: Marine.kJetpackLoop = PrecacheAsset("sound/ns2.fev/marine/common/jetpack_on")
Marine.lua:44: Marine.kJetpackEnd = PrecacheAsset("sound/ns2.fev/marine/common/jetpack_end")

Commander.lua:18: Commander.kSpendCarbonSoundName = PrecacheAsset("sound/ns2.fev/marine/common/comm_spend_metal")
Commander.lua:19: Commander.kSpendPlasmaSoundName = PrecacheAsset("sound/ns2.fev/marine/common/player_spend_nanites")
AlienCommander.lua:18: AlienCommander.kSpawnSound = PrecacheAsset("sound/ns2.fev/alien/structures/generic_spawn_large")
AlienCommander.lua:19: AlienCommander.kSelectSound = PrecacheAsset("sound/ns2.fev/alien/commander/select")
AlienCommander.lua:20: AlienCommander.kChatSound = PrecacheAsset("sound/ns2.fev/alien/common/chat")
AlienCommander.lua:21: AlienCommander.kUpgradeCompleteSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/upgrade_complete")
AlienCommander.lua:22: AlienCommander.kResearchCompleteSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/research_complete")
MarineCommander.lua:21: MarineCommander.kBuildEffect = PrecacheAsset("cinematics/marine/structures/spawn_building.cinematic")
MarineCommander.lua:22: MarineCommander.kBuildBigEffect = PrecacheAsset("cinematics/marine/structures/spawn_building_big.cinematic")
MarineCommander.lua:39: MarineCommander.kOrderClickedEffect = PrecacheAsset("cinematics/marine/order.cinematic")
AlienCommander.lua:14: AlienCommander.kOrderClickedEffect = PrecacheAsset("cinematics/alien/order.cinematic")
AlienCommander.lua:15: AlienCommander.kSpawnSmallEffect = PrecacheAsset("cinematics/alien/structures/spawn_small.cinematic")
AlienCommander.lua:16: AlienCommander.kSpawnLargeEffect = PrecacheAsset("cinematics/alien/structures/spawn_large.cinematic")

Onos.lua:32: Onos.kChargeEffect = PrecacheAsset("cinematics/alien/onos/charge.cinematic")
Onos.lua:33: Onos.kChargeHitEffect = PrecacheAsset("cinematics/alien/onos/charge_hit.cinematic")
Onos.lua:26: Onos.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/onos/spawn") 
Onos.lua:27: Onos.kDieSoundName = PrecacheAsset("sound/ns2.fev/alien/onos/death")
Onos.lua:28: Onos.kFootstepSound = PrecacheAsset("sound/ns2.fev/alien/onos/onos_step")
Onos.lua:29: Onos.kWoundSound = PrecacheAsset("sound/ns2.fev/alien/onos/wound")
Onos.lua:30: Onos.kGoreSound = PrecacheAsset("sound/ns2.fev/alien/onos/gore")

Gorge.lua:42: Gorge.kSoakEffect = PrecacheAsset("cinematics/alien/gorge/soak.cinematic")
Gorge.lua:43: Gorge.kSoakViewEffect = PrecacheAsset("cinematics/alien/gorge/soak_view.cinematic")
Gorge.lua:44: Gorge.kSlideEffect = PrecacheAsset("cinematics/alien/gorge/slide.cinematic")
Gorge.lua:32: Gorge.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/gorge/spawn" )
Gorge.lua:33: Gorge.kDieSoundName = PrecacheAsset("sound/ns2.fev/alien/gorge/death")
Gorge.lua:34: Gorge.kLeftFootstepSound = PrecacheAsset("sound/ns2.fev/alien/gorge/footstep_left")
Gorge.lua:35: Gorge.kRightFootstepSound = PrecacheAsset("sound/ns2.fev/alien/gorge/footstep_right")
Gorge.lua:36: Gorge.kStructureSpawnSound = PrecacheAsset("sound/ns2.fev/alien/structures/spawn_small")
Gorge.lua:37: Gorge.kTauntSound = PrecacheAsset("sound/ns2.fev/alien/gorge/taunt")
Gorge.lua:38: Gorge.kSlideHitSound = PrecacheAsset("sound/ns2.fev/alien/gorge/hit")
Gorge.lua:39: Gorge.kJumpSoundName = PrecacheAsset("sound/ns2.fev/alien/gorge/jump")

Fade.lua:21: Fade.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/fade/spawn") 
Fade.lua:22: Fade.kDieSoundName = PrecacheAsset("sound/ns2.fev/alien/fade/death")
Fade.lua:23: Fade.kTauntSound = PrecacheAsset("sound/ns2.fev/alien/fade/taunt")
Fade.lua:24: Fade.kJumpSound = PrecacheAsset("sound/ns2.fev/alien/fade/jump")

Skulk.lua:20: Skulk.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/skulk/spawn")
Skulk.lua:21: Skulk.kJumpSoundName = PrecacheAsset("sound/ns2.fev/alien/skulk/jump")
Skulk.lua:22: Skulk.kDieSoundName = PrecacheAsset("sound/ns2.fev/alien/skulk/death")
Skulk.lua:23: Skulk.kFootstepSoundLeft = PrecacheAsset("sound/ns2.fev/alien/skulk/footstep_left")
Skulk.lua:24: Skulk.kFootstepSoundRight = PrecacheAsset("sound/ns2.fev/alien/skulk/footstep_right")
Skulk.lua:25: Skulk.kFootstepSoundLeftMetal = PrecacheAsset("sound/ns2.fev/materials/metal/skulk_step_left")
Skulk.lua:26: Skulk.kFootstepSoundRightMetal = PrecacheAsset("sound/ns2.fev/materials/metal/skulk_step_right")
Skulk.lua:27: Skulk.kMetalLayer = PrecacheAsset("sound/ns2.fev/materials/metal/skulk_layer")
Skulk.lua:28: Skulk.kLandSound = PrecacheAsset("sound/ns2.fev/alien/skulk/land")
Skulk.lua:29: Skulk.kWoundSound = PrecacheAsset("sound/ns2.fev/alien/skulk/wound")
Skulk.lua:30: Skulk.kWoundSeriousSound = PrecacheAsset("sound/ns2.fev/alien/skulk/wound_serious")
Skulk.lua:31: Skulk.kIdleSound = PrecacheAsset("sound/ns2.fev/alien/skulk/idle")

Lerk.lua:26: Lerk.kSpawnSoundName = PrecacheAsset("sound/ns2.fev/alien/lerk/spawn")
Lerk.lua:27: Lerk.kDieSoundName = PrecacheAsset("sound/ns2.fev/alien/lerk/death")
Lerk.lua:28: Lerk.kLeftFootstepSound = PrecacheAsset("sound/ns2.fev/alien/lerk/footstep_left")
Lerk.lua:29: Lerk.kRightFootstepSound = PrecacheAsset("sound/ns2.fev/alien/lerk/footstep_right")
Lerk.lua:30: Lerk.kFlapSound = PrecacheAsset("sound/ns2.fev/alien/lerk/flap")

MarineCommander.lua:24: MarineCommander.kSentryFiringSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/sentry_firing")
MarineCommander.lua:25: MarineCommander.kSentryTakingDamageSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/sentry_taking_damage")
MarineCommander.lua:26: MarineCommander.kSoldierLostSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/soldier_lost")
MarineCommander.lua:27: MarineCommander.kSoldierNeedsAmmoSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/soldier_needs_ammo")
MarineCommander.lua:28: MarineCommander.kSoldierNeedsHealthSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/soldier_needs_health")
MarineCommander.lua:29: MarineCommander.kSoldierNeedsOrderSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/soldier_needs_order")
MarineCommander.lua:30: MarineCommander.kUpgradeCompleteSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/upgrade_complete")
MarineCommander.lua:31: MarineCommander.kResearchCompleteSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/research_complete")
MarineCommander.lua:32: MarineCommander.kObjectiveCompletedSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/complete")
MarineCommander.lua:33: MarineCommander.kMoveToWaypointSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/move")
MarineCommander.lua:34: MarineCommander.kAttackOrderSoundName = PrecacheAsset("sound/ns2.fev/marine/voiceovers/move")
MarineCommander.lua:35: MarineCommander.kStructureUnderAttackSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/base_under_attack")
MarineCommander.lua:36: MarineCommander.kBuildStructureSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/build")
MarineCommander.lua:37: MarineCommander.kDefendTargetSound = PrecacheAsset("sound/ns2.fev/marine/voiceovers/commander/defend")
MarineCommander.lua:40: MarineCommander.kPlaceBuildingSound = PrecacheAsset("sound/ns2.fev/marine/structures/generic_spawn")
MarineCommander.lua:41: MarineCommander.kSelectSound = PrecacheAsset("sound/ns2.fev/marine/commander/select")
MarineCommander.lua:42: MarineCommander.kChatSound = PrecacheAsset("sound/ns2.fev/marine/common/chat")
*/