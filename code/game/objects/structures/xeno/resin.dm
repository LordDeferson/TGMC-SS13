/obj/alien/resin
	name = "resin"
	desc = "Looks like some kind of slimy growth."
	icon_state = "Resin1"
	max_integrity = 200
	resistance_flags = XENO_DAMAGEABLE

/obj/alien/resin/attack_hand(mob/living/user)
	balloon_alert(user, "You only scrape at it")
	return TRUE

/obj/alien/resin/sticky
	name = STICKY_RESIN
	desc = "A layer of disgusting sticky slime."
	icon_state = "sticky"
	density = FALSE
	opacity = FALSE
	max_integrity = 36
	plane = FLOOR_PLANE
	layer = ABOVE_WEEDS_LAYER
	hit_sound = SFX_ALIEN_RESIN_MOVE
	var/slow_amt = 8
	/// Does this refund build points when destoryed?
	var/refundable = TRUE

	ignore_weed_destruction = TRUE

/obj/alien/resin/sticky/Initialize(mapload)
	. = ..()
	var/static/list/connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(slow_down_crosser)
	)
	AddElement(/datum/element/connect_loc, connections)

/obj/alien/resin/sticky/proc/slow_down_crosser(datum/source, atom/movable/crosser)
	SIGNAL_HANDLER
	if(crosser.throwing || crosser.buckled)
		return

	if(isvehicle(crosser))
		var/obj/vehicle/vehicle = crosser
		vehicle.last_move_time += slow_amt
		return

	if(!ishuman(crosser))
		return

	if(HAS_TRAIT(crosser, TRAIT_TANK_DESANT))
		return

	if(CHECK_MULTIPLE_BITFIELDS(crosser.allow_pass_flags, HOVERING))
		return

	var/mob/living/carbon/human/victim = crosser

	if(victim.lying_angle)
		return

	victim.next_move_slowdown += slow_amt

/obj/alien/resin/sticky/attack_alien(mob/living/carbon/xenomorph/xeno_attacker, damage_amount = xeno_attacker.xeno_caste.melee_damage, damage_type = BRUTE, damage_flag = MELEE, effects = TRUE, armor_penetration = 0, isrightclick = FALSE)
	if(xeno_attacker.status_flags & INCORPOREAL)
		return FALSE

	if(xeno_attacker.a_intent == INTENT_HARM)
		if(CHECK_BITFIELD(SSticker.mode?.round_type_flags, MODE_ALLOW_XENO_QUICKBUILD) && SSresinshaping.should_refund(src, xeno_attacker) && refundable)
			SSresinshaping.decrement_build_counter(xeno_attacker)
		xeno_attacker.do_attack_animation(src, ATTACK_EFFECT_CLAW)
		playsound(src, SFX_ALIEN_RESIN_BREAK, 25)
		deconstruct(TRUE)
		return

	return ..()

// Praetorian Sticky Resin spit uses this.
/obj/alien/resin/sticky/thin
	name = "thin sticky resin"
	desc = "A thin layer of disgusting sticky slime."
	max_integrity = 6
	slow_amt = 4

	ignore_weed_destruction = FALSE
	refundable = FALSE

/obj/alien/resin/sticky/thin/temporary/Initialize(mapload)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(obj_destruction), MELEE), 3 SECONDS)

/obj/structure/xeno/acid_mine
	name = "acid mine"
	desc = "A weird bulb, filled with acid."
	icon = 'icons/obj/items/mine.dmi'
	icon_state = "acid_mine"
	density = FALSE
	opacity = FALSE
	anchored = TRUE
	max_integrity = 5
	hit_sound = SFX_ALIEN_RESIN_BREAK
	/// The damage dealt to mobs nearby the detonation point of the mine
	var/acid_damage = 30

/obj/structure/xeno/acid_mine/Initialize(mapload)
	. = ..()
	var/static/list/connections = list(
		COMSIG_ATOM_ENTERED = PROC_REF(oncrossed),
	)
	AddElement(/datum/element/connect_loc, connections)

/obj/structure/xeno/acid_mine/obj_destruction(damage_amount, damage_type, damage_flag, mob/living/blame_mob)
	detonate()
	return ..()

/// Checks if the mob walking over the mine is human, and calls detonate if so
/obj/structure/xeno/acid_mine/proc/oncrossed(datum/source, atom/movable/A, oldloc, oldlocs)
	SIGNAL_HANDLER
	if(!ishuman(A))
		return
	if(CHECK_MULTIPLE_BITFIELDS(A.allow_pass_flags, HOVERING))
		return
	INVOKE_ASYNC(src, PROC_REF(detonate))

///Handles detonating the mine, and dealing damage to those nearby
/obj/structure/xeno/acid_mine/proc/detonate()
	for(var/spatter_effect in filled_turfs(get_turf(src), 1, "square", pass_flags_checked = PASS_AIR))
		new /obj/effect/temp_visual/acid_splatter(spatter_effect)
	for(var/mob/living/carbon/human/human_victim AS in cheap_get_humans_near(src,1))
		human_victim.apply_damage(acid_damage/2, BURN, BODY_ZONE_L_LEG, ACID,  penetration = 30)
		human_victim.apply_damage(acid_damage/2, BURN, BODY_ZONE_R_LEG, ACID,  penetration = 30)
		playsound(src, "sound/bullets/acid_impact1.ogg", 10)
	qdel(src)

/obj/structure/xeno/acid_mine/gas_mine
	name = "gas mine"
	desc = "A weird bulb, overflowing with acid. Small wisps of gas escape every so often."
	icon_state = "gas_mine"
	acid_damage = 40

/obj/structure/xeno/acid_mine/gas_mine/detonate()
	var/datum/effect_system/smoke_spread/xeno/acid/opaque/A = new(get_turf(src))
	A.set_up(1,src)
	A.start()
	return ..()
