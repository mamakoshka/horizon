// This item has a small amount of copypasta from jukeboxes, but it's whatever, low surface amount.
// It wouldn't be an issue to create a common interface if jukeboxes (the machine) werent such a fucking mess in the first place

/obj/item/boombox
	name = "boombox"
	desc = "A dusty, gray, bulky, battery-powered, auto-looping stereo cassette player. An ancient relic from prehistoric times on that one planet with humans and stuff. Yeah, that one."
	icon = 'icons/obj/items/boombox/boombox.dmi'
	lefthand_file = 'icons/obj/items/boombox/bb_lefthand.dmi'
	righthand_file = 'icons/obj/items/boombox/bb_righthand.dmi'
	icon_state = "boombox"
	w_class = WEIGHT_CLASS_NORMAL
	force = 5
	custom_price = PAYCHECK_HARD * 20
	/// Reference to the song list from the jukebox subsystem.
	var/static/list/songs
	/// Currently selected track.
	var/datum/jukebox_track/selected_track
	/// Currently playing track.
	var/datum/jukebox_playing_track/playing_track
	/// Volume of the songs played
	var/volume = 50
	/// Is the current song paused?
	var/paused = FALSE

/obj/item/boombox/Initialize()
	. = ..()
	if(!songs)
		songs = SSjukebox.tracks

/obj/item/boombox/update_icon_state()
	. = ..()
	icon_state = playing_track ? "boombox_active" : initial(icon_state)

/obj/item/boombox/attack_self(mob/user)
	ui_interact(user)
	return TRUE

/obj/item/boombox/RightClick(mob/user)
	ui_interact(user)
	return TRUE

/obj/item/boombox/attack_robot(mob/user)
	ui_interact(user)
	return TRUE

/obj/item/boombox/Destroy()
	stop_song()
	return..()

/obj/item/boombox/proc/play_song()
	if(!selected_track)
		return
	if(playing_track)
		return
	var/free_channel = SSjukebox.get_free_channel()
	if(!free_channel)
		return
	playing_track = new(src, selected_track, free_channel, BOOMBOX_RANGE_MULTIPLIER)
	say("Now playing: [playing_track.track.song_artist] - [playing_track.track.song_title]")
	update_appearance()

/obj/item/boombox/proc/toggle_pause()
	if(playing_track)
		paused = !paused

/obj/item/boombox/proc/stop_song()
	if(playing_track)
		qdel(playing_track)

/// called by the song ending from the jukebox subsystem
/obj/item/boombox/proc/song_ended()
	playing_track = null
	update_appearance()

/obj/item/boombox/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Boombox", name)
		ui.open()

/obj/item/boombox/ui_data(mob/user)
	. = list()

	.["volume"] = volume

	// Current track data
	.["playing_track"] = null
	if(playing_track)
		var/datum/jukebox_track/currently_playing = playing_track.track
		.["playing_track"] = list()
		.["playing_track"]["artist"] = currently_playing.song_artist
		.["playing_track"]["title"] = currently_playing.song_title
		.["playing_track"]["length"] = (currently_playing.song_length SECONDS)

	// Selected track data
	.["selected_track"] = null
	if(selected_track)
		.["selected_track"] = list()
		.["selected_track"]["artist"] = selected_track.song_artist
		.["selected_track"]["title"] = selected_track.song_title
		.["selected_track"]["length"] = (selected_track.song_length SECONDS)
		.["selected_track"]["ref"] = REF(selected_track)


/obj/item/boombox/ui_static_data(mob/user)
	. = list()
	.["songs"] = list()
	// Go through every song, capture the artist and title and obj ref
	for(var/datum/jukebox_track/song in songs)
		var/list/track_data = list(
			artist = song.song_artist,
			title = song.song_title,
			ref = REF(song)
		)
		.["songs"] += list(track_data)

/obj/item/boombox/ui_act(action, list/params)
	. = ..()
	if(. || QDELETED(src)) return
	switch(action)
		if("toggle_play")
			if(playing_track)
				stop_song()
			else
				play_song()
			return TRUE
		if("stop")
			if(playing_track)
				stop_song()
				return TRUE
		if("play")
			if(playing_track)
				stop_song()
			play_song()
			return TRUE
		if("select_track")
			var/datum/jukebox_track/new_track = locate(params["track"])
			if(!new_track || !istype(new_track))
				return
			selected_track = new_track
			return TRUE
		if("set_volume")
			var/new_volume = params["volume"]
			switch(new_volume)
				if("reset")
					volume = initial(volume)
					return TRUE
				if("min")
					volume = max(volume - 10, 0)
					return TRUE
				if("max")
					volume = min(volume + 10, 100)
					return TRUE
				else
					if(text2num(new_volume) != null)
						volume = text2num(new_volume)
						return TRUE
