/// Time it takes for the inflatable to slowly deflate
#define SLOW_DEFLATE_TIME 2.6 SECONDS

/obj/item/inflatable
	name = "inflatable wall"
	desc = "A neatly folded package of a rubber-like material, with a re-usable pulltab sticking out from it."
	icon = 'icons/obj/items/inflatables.dmi'
	icon_state = "folded"
	w_class = WEIGHT_CLASS_SMALL
	var/deploy_structure = /obj/structure/inflatable

/obj/item/inflatable/Initialize()
	. = ..()
	src.desc = "[src.desc]\nThere is a warning in big bold letters below the instructions, \"[SPAN_WARNING("WARNING: RETIRE IMMEDIATELY AFTER PULLING TAB. DO NOT HOLD. STAND BACK UNTIL INFLATED.")]\""

/obj/item/inflatable/attack_self(mob/user, modifiers)
	if(!deploy_structure) return
	if(locate(/obj/structure/inflatable) in user.loc)
		to_chat(user, SPAN_WARNING("There is already an inflatable here!"))
		return

	playsound(loc, 'sound/items/zip.ogg', 75, TRUE)
	to_chat(user, SPAN_NOTICE("You lay \the [src] onto the floor and pull on its expand tab."))

	if(do_after(user, 0.70 SECONDS, src))
		// We put it on the floor, and quickly pulled on the tab
		src.inflate(user)
	else
		// We just drop it to the ground cause we somehow couldn't pull on the tab quick enough.
		to_chat(user, SPAN_WARNING("You lost your grip on the tab!"))
		user.dropItemToGround(src)

/obj/item/inflatable/suicide_act(mob/user)
	user.visible_message(
		SPAN_SUICIDE("[user] stuffs the [src] into one of their cavities and is pulling on the [src]'s pulltab! It looks like [user.p_theyre()] trying to commit suicide by becoming a balloon animal!")
	)
	if(prob(15) && iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		carbon_user.inflate_gib()
	src.inflate(user)
	return BRUTELOSS

/obj/item/inflatable/proc/inflate(mob/user)
	var/obj/structure/inflatable/new_inflatable = new deploy_structure(user.loc, deployer_item=src)
	transfer_fingerprints_to(new_inflatable)
	new_inflatable.add_fingerprint(user)
	qdel(src)

/// A temporary structure that can be deployed by using an item
/// Will deflate after a while, or after being pierced.
/obj/structure/inflatable
	name = "inflatable"
	desc = "An inflated membrane. Do not puncture."
	icon = 'icons/obj/structures/inflatables.dmi'
	icon_state = "wall"
	density = TRUE
	anchored = TRUE
	max_integrity = 50
	CanAtmosPass = ATMOS_PASS_DENSITY
	var/deflating = FALSE
	var/deployer_item = /obj/item/inflatable

/obj/structure/inflatable/Initialize(obj/item/inflatable/deployer_item)
	. = ..()
	// We probably want to make this retract into its proper type when deflating, done here
	if(deployer_item)
		src.deployer_item = deployer_item.type

	// And as the sprite is larger than 32x32, we need to translate it a little bit
	var/matrix/self_matrix = new
	self_matrix.Translate(-4, -4)
	transform = self_matrix

/obj/structure/inflatable/attackby(obj/item/I, mob/living/user, params)
	// We're already deflating, no real point doing anything special
	if (deflating)
		return

	if (isprojectile(I) || I.sharpness > NONE)
		// A projectile or sharp tool is hitting us, and we're structurally weakened - pop
		if(get_integrity() <= (max_integrity * 0.7))
			src.deflate(violent=TRUE)
			return

	if (src.get_integrity() <= (max_integrity * 0.25))
		src.deflate()

	return ..()

/// Causes our structure to deflate, violent will make it blow into pieces
/obj/structure/inflatable/proc/deflate(violent = FALSE)
	if (deflating)
		return
	if (violent)
		playsound(loc, 'sound/effects/snap.ogg', 75, TRUE, frequency = 32000, falloff_distance = 2)
		new /obj/effect/decal/cleanable/plastic/inflatables(get_turf(src))
		qdel(src)
		return
	playsound(loc, 'sound/effects/smoke.ogg', 60, TRUE)
	var/matrix/matrix = new
	matrix.Scale(0.6)
	animate(src, SLOW_DEFLATE_TIME, transform = matrix)
	addtimer(CALLBACK(src, .proc/post_deflate), SLOW_DEFLATE_TIME)

/obj/structure/inflatable/proc/post_deflate()
	var/obj/item/inflatable/inflatable_item = new deployer_item(src.loc)
	transfer_fingerprints_to(inflatable_item)
	qdel(src)

// Custom broken plastic decal
/obj/effect/decal/cleanable/plastic/inflatables
	name = "rubber shreds"
	color = "#e9d285"

#undef SLOW_DEFLATE_TIME
