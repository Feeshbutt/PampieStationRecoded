//Mob vars
/mob/living
	var/arousalloss = 0									//How aroused the mob is.
	var/min_arousal = AROUSAL_MINIMUM_DEFAULT			//The lowest this mobs arousal will get. default = 0
	var/max_arousal = AROUSAL_MAXIMUM_DEFAULT			//The highest this mobs arousal will get. default = 100
	var/arousal_rate = AROUSAL_START_VALUE				//The base rate that arousal will increase in this mob.
	var/arousal_loss_rate = AROUSAL_START_VALUE			//How easily arousal can be relieved for this mob.
	var/canbearoused = FALSE					//Mob-level disabler for arousal. Starts off and can be enabled as features are added for different mob types.
	var/mb_cd_length = 5 SECONDS						//5 second cooldown for masturbating because fuck spam.
	var/mb_cd_timer = 0									//The timer itself

/mob/living/carbon/human
	canbearoused = TRUE

	var/saved_underwear = ""//saves their underwear so it can be toggled later
	var/saved_undershirt = ""
	var/saved_socks = ""
	var/hidden_underwear = FALSE
	var/hidden_undershirt = FALSE
	var/hidden_socks = FALSE

//Species vars
/datum/species
	var/arousal_gain_rate = AROUSAL_START_VALUE //Rate at which this species becomes aroused
	var/arousal_lose_rate = AROUSAL_START_VALUE //Multiplier for how easily arousal can be relieved
	var/list/cum_fluids = list("semen")
	var/list/milk_fluids = list("milk")
	var/list/femcum_fluids = list("femcum")

//Mob procs
/mob/living/carbon/human/proc/underwear_toggle()
	set name = "Toggle undergarments"
	set category = "IC"

	var/confirm = input(src, "Select what part of your form to alter", "Undergarment Toggling") as null|anything in list("Top", "Bottom", "Socks", "All")
	if(!confirm)
		return
	if(confirm == "Top")
		hidden_undershirt = !hidden_undershirt

	if(confirm == "Bottom")
		hidden_underwear = !hidden_underwear

	if(confirm == "Socks")
		hidden_socks = !hidden_socks

	if(confirm == "All")
		var/on_off = (hidden_undershirt || hidden_underwear || hidden_socks) ? FALSE : TRUE
		hidden_undershirt = on_off
		hidden_underwear = on_off
		hidden_socks = on_off

	update_body()

/mob/living/proc/handle_arousal(times_fired)
	return

/mob/living/carbon/handle_arousal(times_fired)
	if(!canbearoused || !dna)
		return
	var/datum/species/S = dna.species
	if(!S || (times_fired % 36) || !getArousalLoss() >= max_arousal)//Totally stolen from breathing code. Do this every 36 ticks.
		return
	var/our_loss = arousal_rate * S.arousal_gain_rate
	if(HAS_TRAIT(src, TRAIT_EXHIBITIONIST) && client)
		var/amt_nude = 0
		for(var/obj/item/organ/genital/G in internal_organs)
			if(G.is_exposed())
				amt_nude++
		if(amt_nude)
			var/watchers = 0
			for(var/mob/living/L in view(world.view, src))
				if(!istype(L))
					continue
				if(L.client && !L.stat && !L.eye_blind && (locate(src) in viewers(world.view, L)))
					watchers++
			if(watchers)
				our_loss += (amt_nude * watchers) + S.arousal_gain_rate
	adjustArousalLoss(our_loss)

/mob/living/proc/getArousalLoss()
	return arousalloss

/mob/living/proc/adjustArousalLoss(amount, updating_arousal=1)
	if(status_flags & GODMODE || !canbearoused)
		return FALSE
	arousalloss = CLAMP(arousalloss + amount, min_arousal, max_arousal)
	if(updating_arousal)
		updatearousal()

/mob/living/proc/setArousalLoss(amount, updating_arousal=1)
	if(status_flags & GODMODE || !canbearoused)
		return FALSE
	arousalloss = CLAMP(amount, min_arousal, max_arousal)
	if(updating_arousal)
		updatearousal()

/mob/living/proc/getPercentAroused()
	var/percentage = ((100 / max_arousal) * arousalloss)
	return percentage

/mob/living/proc/isPercentAroused(percentage)//returns true if the mob's arousal (measured in a percent of 100) is greater than the arg percentage.
	if(!isnum(percentage) || percentage > 100 || percentage < 0)
		CRASH("Provided percentage is invalid")
	if(getPercentAroused() >= percentage)
		return TRUE
	return FALSE

//H U D//
/mob/living/proc/updatearousal()
	update_arousal_hud()

/mob/living/carbon/updatearousal()
	. = ..()
	for(var/obj/item/organ/genital/G in internal_organs)
		if(istype(G))
			var/datum/sprite_accessory/S
			switch(G.type)
				if(/obj/item/organ/genital/penis)
					S = GLOB.cock_shapes_list[G.shape]
				if(/obj/item/organ/genital/testicles)
					S = GLOB.balls_shapes_list[G.shape]
				if(/obj/item/organ/genital/vagina)
					S = GLOB.vagina_shapes_list[G.shape]
				if(/obj/item/organ/genital/breasts)
					S = GLOB.breasts_shapes_list[G.shape]
			if(S?.alt_aroused)
				G.aroused_state = isPercentAroused(G.aroused_amount)
			else
				G.aroused_state = FALSE
			G.update_appearance()

/mob/living/proc/update_arousal_hud()
	return FALSE

/mob/living/carbon/human/update_arousal_hud()
	if(!client || !(hud_used?.arousal))
		return FALSE
	if(!canbearoused)
		hud_used.arousal.icon_state = ""
		return FALSE
	if(stat == DEAD)
		hud_used.arousal.icon_state = "arousal0"
	else
		var/value = FLOOR(getPercentAroused(), 10)
		hud_used.arousal.icon_state = "arousal[value]"
	return TRUE

/obj/screen/arousal
	name = "arousal"
	icon_state = "arousal0"
	icon = 'modular_citadel/icons/obj/genitals/hud.dmi'
	screen_loc = ui_arousal

/obj/screen/arousal/Click()
	if(!isliving(usr))
		return FALSE
	var/mob/living/M = usr
	if(M.canbearoused)
		M.mob_climax()
		return TRUE
	else
		to_chat(M, "<span class='warning'>Arousal is disabled. Feature is unavailable.</span>")


/mob/living/proc/mob_climax()//This is just so I can test this shit without being forced to add actual content to get rid of arousal. Will be a very basic proc for a while.
	set name = "Masturbate"
	set category = "IC"
	if(canbearoused && !restrained() && !stat)
		if(mb_cd_timer <= world.time)
			//start the cooldown even if it fails
			mb_cd_timer = world.time + mb_cd_length
			if(getArousalLoss() >= 33)//one third of average max_arousal or greater required
				visible_message("<span class='danger'>[src] starts masturbating!</span>", \
								"<span class='userdanger'>You start masturbating.</span>")
				if(do_after(src, 30, target = src))
					visible_message("<span class='danger'>[src] relieves [p_them()]self!</span>", \
								"<span class='userdanger'>You have relieved yourself.</span>")
					SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
					setArousalLoss(min_arousal)
			else
				to_chat(src, "<span class='notice'>You aren't aroused enough for that.</span>")

/obj/item/organ/genital/proc/climaxable(mob/living/carbon/human/H, silent = FALSE) //returns the fluid source (ergo reagents holder) if found.
	if(CHECK_BITFIELD(genital_flags, GENITAL_FUID_PRODUCTION))
		. = reagents
	else
		if(linked_organ)
			. = linked_organ.reagents
	if(!. && !silent)
		to_chat(H, "<span class='warning'>Your [name] is unable to produce it's own fluids, it's missing the organs for it.</span>")

/mob/living/carbon/human/proc/do_climax(datum/reagents/R, atom/target, obj/item/organ/genital/G, spill = TRUE)
	if(!G)
		return
	SEND_SIGNAL(src, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
	if(!target || !R)
		return
	var/turfing = isturf(target)
	if(spill & R.total_volume >= 5)
		R.reaction(turfing ? target : target.loc, TOUCH, 1, 0)
	if(!turfing)
		R.trans_to(target, R.total_volume * (spill ? G.fluid_transfer_factor : 1))
	R.clear_reagents()

//These are various procs that we'll use later, split up for readability instead of having one, huge proc.
//For all of these, we assume the arguments given are proper and have been checked beforehand.
/mob/living/carbon/human/proc/mob_masturbate(obj/item/organ/genital/G, mb_time = 30) //Masturbation, keep it gender-neutral
	var/datum/reagents/fluid_source = G.climaxable(src)
	if(!fluid_source)
		return
	var/obj/item/organ/genital/PP = CHECK_BITFIELD(G.genital_flags, MASTURBATE_LINKED_ORGAN) ? G.linked_organ : G
	if(!PP)
		to_chat(src, "<span class='warning'>You shudder, unable to cum with your [name].</span>")
	if(mb_time)
		visible_message("<span class='love'>[src] starts to [G.masturbation_verb] [p_their()] [G.name].</span>", \
							"<span class='userlove'>You start to [G.masturbation_verb] your [G.name].</span>")
		if(!do_after(src, mb_time, target = src) || !G.climaxable(src, TRUE))
			return
	visible_message("<span class='love'>[src] orgasms, [PP.orgasm_verb][isturf(loc) ? " onto [loc]" : ""]!</span>", \
						"<span class='userlove'>You orgasm, [PP.orgasm_verb][isturf(loc) ? " onto [loc]" : ""].</span>")
	do_climax(fluid_source, loc, G)

/mob/living/carbon/human/proc/mob_climax_outside(obj/item/organ/genital/G, mb_time = 30) //This is used for forced orgasms and other hands-free climaxes
	var/datum/reagents/fluid_source = G.climaxable(src, TRUE)
	if(!fluid_source)
		visible_message("<span class='danger'>[src] shudders, their [G.name] unable to cum.</span>", \
							"<span class='userdanger'>Your [G.name] cannot cum, giving no relief.</span>")
		return
	if(mb_time) //as long as it's not instant, give a warning
		visible_message("<span class='love'>[src] looks like they're about to cum.</span>", \
							"<span class='userlove'>You feel yourself about to orgasm.</span>")
		if(!do_after(src, mb_time, target = src) || !G.climaxable(src, TRUE))
			return
	visible_message("<span class='love'>[src] orgasms[isturf(loc) ? " onto [loc]" : ""], using [p_their()] [G.name]!</span>", \
						"<span class='userlove'>You climax[isturf(loc) ? " onto [loc]" : ""] with your [G.name].</span>")
	do_climax(fluid_source, loc, G)

/mob/living/carbon/human/proc/mob_climax_partner(obj/item/organ/genital/G, mob/living/L, spillage = TRUE, mb_time = 30) //Used for climaxing with any living thing
	var/datum/reagents/fluid_source = G.climaxable(src)
	if(!fluid_source)
		return
	if(mb_time) //Skip warning if this is an instant climax.
		visible_message("<span class='love'>[src] is about to climax with [L]!</span>", \
						"<span class='userlove'>You're about to climax with [L]!</span>")
		if(!do_after(src, mb_time, target = src) || !in_range(src, L) || !G.climaxable(src, TRUE))
			return
	if(spillage)
		visible_message("<span class='love'>[src] climaxes with [L], overflowing and spilling, using [p_their()] [G.name]!</span>", \
						"<span class='userlove'>You orgasm with [L], spilling out of them, using your [G.name].</span>")
	else //knots and other non-spilling orgasms
		visible_message("<span class='love'>[src] climaxes with [L], [p_their()] [G.name] spilling nothing!</span>", \
						"<span class='userlove'>You ejaculate with [L], your [G.name] spilling nothing.</span>")
	SEND_SIGNAL(L, COMSIG_ADD_MOOD_EVENT, "orgasm", /datum/mood_event/orgasm)
	do_climax(fluid_source, spillage ? loc : L, G, spillage)


/mob/living/carbon/human/proc/mob_fill_container(obj/item/organ/genital/G, obj/item/reagent_containers/container, mb_time = 30) //For beaker-filling, beware the bartender
	var/datum/reagents/fluid_source = G.climaxable(src)
	if(!fluid_source)
		return
	if(mb_time)
		visible_message("<span class='love'>[src] starts to [G.masturbation_verb] their [G.name] over [container].</span>", \
							"<span class='userlove'>You start to [G.masturbation_verb] your [G.name] over [container].</span>")
		if(!do_after(src, mb_time, target = src) || !in_range(src, container) || !G.climaxable(src, TRUE))
			return
	visible_message("<span class='love'>[src] uses [p_their()] [G.name] to fill [container]!</span>", \
						"<span class='userlove'>You used your [G.name] to fill [container].</span>")
	do_climax(fluid_source, container, G, FALSE)

/mob/living/carbon/human/proc/pick_masturbate_genitals()
	var/list/genitals_list = list()
	var/list/worn_stuff = get_equipped_items()

	for(var/obj/item/organ/genital/G in internal_organs)
		if(CHECK_BITFIELD(G.genital_flags, CAN_MASTURBATE_WITH) && G.is_exposed(worn_stuff)) //filter out what you can't masturbate with
			if(CHECK_BITFIELD(G.genital_flags, MASTURBATE_LINKED_ORGAN) && !G.linked_organ)
				continue
			genitals_list += G
	if(genitals_list.len)
		var/obj/item/organ/genital/ret_organ = input(src, "with what?", "Masturbate", null)  as null|obj in genitals_list
		return ret_organ


/mob/living/carbon/human/proc/pick_climax_genitals()
	var/list/genitals_list = list()
	var/list/worn_stuff = get_equipped_items()

	for(var/obj/item/organ/genital/G in internal_organs)
		if(CHECK_BITFIELD(G.genital_flags, CAN_CLIMAX_WITH) && G.is_exposed(worn_stuff)) //filter out what you can't masturbate with
			genitals_list += G
	if(genitals_list.len)
		var/obj/item/organ/genital/ret_organ = input(src, "with what?", "Climax", null)  as null|obj in genitals_list
		return ret_organ


/mob/living/carbon/human/proc/pick_partner()
	var/list/partners = list()
	if(pulling)
		partners += pulling
	if(pulledby)
		partners += pulledby
	//Now we got both of them, let's check if they're proper
	for(var/mob/living/L in partners)
		if(iscarbon(L))
			var/mob/living/carbon/C = L
			if(!C.exposed_genitals.len && !C.is_groin_exposed() && !C.is_chest_exposed()) //Nothing through_clothing, no proper partner.
				partners -= C
	//NOW the list should only contain correct partners
	if(!partners.len)
		return //No one left.
	var/mob/living/target = input(src, "With whom?", "Sexual partner", null) as null|anything in partners //pick one, default to null
	if(target && in_range(src, target))
		return target

/mob/living/carbon/human/proc/pick_climax_container()
	var/list/containers_list = list()

	for(var/obj/item/reagent_containers/container in held_items)
		if(container.is_open_container() || istype(container, /obj/item/reagent_containers/food/snacks))
			containers_list += container

	if(containers_list.len)
		var/obj/item/reagent_containers/SC = input(src, "Into or onto what?(Cancel for nowhere)", null)  as null|obj in containers_list
		if(SC && in_range(src, SC))
			return SC
	return null //If nothing correct, give null.

/mob/living/carbon/human/proc/available_rosie_palms(silent = FALSE)
	if(restrained(TRUE)) //TRUE ignores grabs
		if(!silent)
			to_chat(src, "<span class='warning'>You can't do that while restrained!</span>")
		return FALSE
	if(!get_num_arms() || !get_empty_held_indexes())
		if(!silent)
			to_chat(src, "<span class='warning'>You need at least one free arm.</span>")
		return FALSE
	return TRUE

//Here's the main proc itself
/mob/living/carbon/human/mob_climax(forced_climax=FALSE) //Forced is instead of the other proc, makes you cum if you have the tools for it, ignoring restraints
	if(mb_cd_timer > world.time)
		if(!forced_climax) //Don't spam the message to the victim if forced to come too fast
			to_chat(src, "<span class='warning'>You need to wait [DisplayTimeText((mb_cd_timer - world.time), TRUE)] before you can do that again!</span>")
		return
	mb_cd_timer = world.time + mb_cd_length

	if(canbearoused && has_dna())
		if(stat == DEAD)
			if(!forced_climax)
				to_chat(src, "<span class='warning'>You can't do that while dead!</span>")
			return
		if(forced_climax) //Something forced us to cum, this is not a masturbation thing and does not progress to the other checks
			for(var/obj/item/organ/genital/G in internal_organs)
				if(!CHECK_BITFIELD(G.genital_flags, CAN_CLIMAX_WITH)) //Skip things like wombs and testicles
					continue
				var/mob/living/partner
				var/check_target
				var/list/worn_stuff = get_equipped_items()

				if(G.is_exposed(worn_stuff))
					if(pulling) //Are we pulling someone? Priority target, we can't be making option menus for this, has to be quick
						if(isliving(pulling)) //Don't fuck objects
							check_target = pulling
					if(pulledby && !check_target) //prioritise pulled over pulledby
						if(isliving(pulledby))
							check_target = pulledby
					//Now we should have a partner, or else we have to come alone
					if(check_target)
						if(iscarbon(check_target)) //carbons can have clothes
							var/mob/living/carbon/C = check_target
							if(C.exposed_genitals.len || C.is_groin_exposed() || C.is_chest_exposed()) //Are they naked enough?
								partner = C
						else //A cat is fine too
							partner = check_target
					if(partner) //Did they pass the clothing checks?
						mob_climax_partner(G, partner, mb_time = 0) //Instant climax due to forced
						continue //You've climaxed once with this organ, continue on
				//not exposed OR if no partner was found while exposed, climax alone
				mob_climax_outside(G, mb_time = 0) //removed climax timer for sudden, forced orgasms
			//Now all genitals that could climax, have.
			//Since this was a forced climax, we do not need to continue with the other stuff
			return
		//If we get here, then this is not a forced climax and we gotta check a few things.

		if(stat == UNCONSCIOUS) //No sleep-masturbation, you're unconscious.
			to_chat(src, "<span class='warning'>You must be conscious to do that!</span>")
			return
		if(getArousalLoss() < 33) //flat number instead of percentage
			to_chat(src, "<span class='warning'>You aren't aroused enough for that!</span>")
			return

		//Ok, now we check what they want to do.
		var/choice = input(src, "Select sexual activity", "Sexual activity:") as null|anything in list("Masturbate", "Climax alone", "Climax with partner", "Fill container")

		switch(choice)
			if("Masturbate")
				if(!available_rosie_palms())
					return
				//We got hands, let's pick an organ
				var/obj/item/organ/genital/picked_organ = pick_masturbate_genitals()
				if(picked_organ && available_rosie_palms(TRUE))
					mob_masturbate(picked_organ)
					return

			if("Climax alone")
				if(!available_rosie_palms())
					return
				var/obj/item/organ/genital/picked_organ = pick_climax_genitals()
				if(picked_organ && available_rosie_palms(TRUE))
					mob_climax_outside(picked_organ)

			if("Climax with partner")
				//We need no hands, we can be restrained and so on, so let's pick an organ
				var/obj/item/organ/genital/picked_organ = pick_climax_genitals()
				if(picked_organ)
					var/mob/living/partner = pick_partner() //Get someone
					if(partner)
						var/spillage = input(src, "Would your fluids spill outside?", "Choose overflowing option", "Yes") as null|anything in list("Yes", "No")
						if(spillage && in_range(src, partner))
							mob_climax_partner(picked_organ, partner, spillage == "Yes" ? TRUE : FALSE)

			if("Fill container")
				//We'll need hands and no restraints.
				if(!available_rosie_palms())
					return
				//We got hands, let's pick an organ
				var/obj/item/organ/genital/picked_organ
				picked_organ = pick_climax_genitals() //Gotta be climaxable, not just masturbation, to fill with fluids.
				if(picked_organ)
					//Good, got an organ, time to pick a container
					var/obj/item/reagent_containers/fluid_container = pick_climax_container()
					if(fluid_container && available_rosie_palms(TRUE))
						mob_fill_container(picked_organ, fluid_container)
						return