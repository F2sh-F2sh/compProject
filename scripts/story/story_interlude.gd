class_name StoryInterlude
extends StoryIntro

## A short run of story pictures between parts of the Novices' Way, told the
## same way as the opening (and built from the same pixel art): what happened
## elsewhere when the great bell rang ("bell"), and what Echidna saw when the
## observatory's dome opened ("dome"). Set `kind` on the scene. Hold Esc skips.
##
## The chapter's end card leads here; the next stop comes after the last
## picture (`_next_scene`).

## The wing kinds ("kiln", "cistern", "lamps", "galleries") follow each wing's bell and lead back to the Landing;
## "eye" follows the fourth and leads to the Eye; "stillness" and "sky" are the two endings.
@export_enum("bell", "dome", "kiln", "cistern", "lamps", "galleries", "eye", "stillness", "sky") var kind := "bell"


func _make_pictures() -> Array:
	var cold := {"shadow": Color(0.02, 0.03, 0.08), "saturation": 0.8, "vignette": 0.65}
	var hearth := {"light": Color(1.04, 0.97, 0.9), "saturation": 0.88, "vignette": 0.62}
	var memory := {"light": Color(1.06, 0.96, 0.82), "saturation": 0.45, "vignette": 0.75}
	match kind:
		"kiln":
			return [
				{"era": "FAR BELOW", "lines": ["The Forge Bell rang, and its four notes ran down the mountain.",
						"In Nan's kitchen the cold stove lit itself. Nan looked up from her chair, and almost said a name."],
					"build": _nan_hearth.bind(false), "grade": hearth, "zoom": [1.0, 1.06], "from": Vector2(0, 10), "to": Vector2(-14, 4), "min": [4.6, 6.4]},
				{"era": "THE LANDING", "lines": ["Back on the Landing, small chalk footprints led from the first door to the second.",
						"They stopped at a door with water seeping under it."],
					"build": _landing_picture.bind(1), "grade": cold, "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [4.6, 4.6]},
			]
		"cistern":
			return [
				{"card": true, "lines": ["In her notebook, Echidna wrote the sentence from the sky:\nICE · FREEZE · SELF · PERSIST.\n\nShe could already cast two of those words herself."], "min": [6.4]},
				{"era": "THE LANDING", "lines": ["On the wall, in chalk, a small hand had written a line: “Don't use the last one. —W”"],
					"build": _landing_picture.bind(2), "grade": cold, "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [5.5]},
			]
		"lamps":
			return [
				{"era": "SIXTY YEARS AGO", "lines": ["The Prior's memory showed the night of the spell from Ilse's side: Wren asleep, the healers gone, the candle low.",
						"Ilse could not bear to wait for the morning. She sang the four notes one last time, and then she wrote the sentence."],
					"build": _ilse_sings, "grade": memory, "music": "lullaby.wav", "music_db": -8.0,
					"zoom": [1.0, 1.08], "from": Vector2(20, 0), "to": Vector2(-20, 10), "min": [6.0, 6.6]},
				{"era": "THE LANDING", "lines": ["Ilse was not a villain. She was a mother who would not let go."],
					"build": _landing_picture.bind(3), "grade": cold, "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [5.0]},
			]
		"galleries":
			return [
				{"era": "THE FOLDED GALLERIES", "lines": ["Behind the last door, Wren had been waiting.", {"who": "wren", "face": "pleading", "text": "Mum won't let go. Please."},
						{"who": "wren", "face": "pleading", "text": "I want it to end. I just don't want Mum to be alone."}],
					"build": _wren_door, "grade": hearth, "zoom": [1.0, 1.1], "from": Vector2(0, 10), "to": Vector2(0, -6), "min": [5.6, 5.0]},
				{"era": "THE LANDING", "lines": ["The Fold Bell rang. All four bell-lights were lit."],
					"build": _landing_picture.bind(4), "grade": cold, "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [4.6]},
			]
		"eye":
			return [
				{"era": "THE LANDING", "lines": ["The four bell-lights joined into one beam of light, and the last door opened."],
					"build": _landing_picture.bind(5), "grade": cold, "zoom": [1.0, 1.1], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [5.0]},
				{"era": "FAR BELOW", "lines": ["In Lowbell, Nan sat out on her porch and hummed four notes. She didn't know where she had learned them."],
					"build": _porch_hum, "grade": cold, "music": "lullaby.wav", "music_db": -9.0,
					"zoom": [1.3, 1.36], "from": Vector2(-16, 92), "to": Vector2(-24, 96), "min": [6.6]},
				{"era": "THE EYE", "lines": ["Echidna went down into the Eye. Something vast was folded in the dark below her, breathing slowly."],
					"build": _descent, "grade": cold, "zoom": [1.0, 1.06], "from": Vector2(30, -30), "to": Vector2(-10, 20), "min": [7.0]},
			]
		"stillness":
			return _stillness_pictures()
		"sky":
			return _sky_pictures()
	if kind == "dome":
		return [
			{"era": "THE OBSERVATORY", "lines": ["The dome opened, and for the first time in years Echidna saw the stars.",
					"Four of them were dark, and the dark spelled a sentence: ICE · FREEZE · SELF · PERSIST.",
					{"who": "echidna", "face": "surprised", "text": "It's still being cast. Sixty years, and it's still being cast."}],
				"build": _dome_gap, "grade": cold, "zoom": [1.0, 1.08], "from": Vector2(0, 40), "to": Vector2(0, -24), "min": [4.8, 6.6, 4.0]},
			{"era": "THROUGH THE LENS", "lines": ["Through a lens in the floor she saw a room far below, white with frost: a bed, and a woman kneeling beside it.",
					"And over them, folded tight, something vast, with wings."],
				"build": _lens_view, "grade": {"shadow": Color(0.02, 0.03, 0.08), "saturation": 0.6, "vignette": 0.95},
				"zoom": [1.12, 1.0], "from": Vector2(0, 30), "to": Vector2(0, -20), "min": [6.4, 5.4]},
			{"era": "THE LONG STAIR", "lines": ["Under the lens a stair wound down into the mountain. At its foot, five doors waited, white with frost.",
					"Only one was warm, and small chalk footprints led to it."],
				"build": _landing_arrival, "grade": cold, "zoom": [1.0, 1.08], "from": Vector2(-20, -10), "to": Vector2(10, 10), "min": [6.0, 5.0]},
		]
	# The great bell, rung at last (the teammate's bell aftermath and these
	# pictures tell the same moment; this is the one the game plays)
	return [
		{"era": "THE WAKING TONE", "lines": ["For the first time in nine years, the great bell's voice crossed the mountain: four notes, all the way down to Lowbell."],
			"build": _peal_crosses, "grade": cold, "music": "bell_peal.wav", "music_db": -4.0,
			"zoom": [1.0, 1.06], "from": Vector2(0, -20), "to": Vector2(0, 16), "min": [8.0]},
		{"era": "LOWBELL", "lines": ["Far below, a wind chime answered. By her hearth, Nan began to hum along without knowing why.",
				"She looked at the door and said half a name.", {"who": "nan", "face": "lost", "text": "Ech..."}],
			"build": _nan_hearth.bind(true), "grade": hearth, "zoom": [1.0, 1.06], "from": Vector2(0, 10), "to": Vector2(-14, 4), "min": [5.6, 5.6]},
		{"card": true, "lines": ["“The tone buys us time. The Eye still holds the frozen hour. Follow the old rune passages up to the observatory.”\n\n— the Bellkeeper's last note"], "min": [6.6]},
		{"era": "THE BELFRY", "lines": ["The bell could hold the Hush back. It could not stop what made it.", {"who": "echidna", "face": "determined", "text": "Then I'll find what made it."},
				"And on the stair above it, someone had drawn a small chalk star. It had not been there before."],
			"build": _chalk_star_stair, "grade": cold, "zoom": [1.0, 1.1], "from": Vector2.ZERO, "to": Vector2(10, -6), "min": [5.0, 3.6, 6.0]},
	]


func _next_scene() -> String:
	match kind:
		"bell":
			return Journey.OBSERVATORY
		"eye", "stillness":
			return Journey.EYE
		"sky":
			return Journey.TITLE
	return Journey.LANDING


## The good ending is saved when its pictures are left (finished, or skipped
## with Esc). The Spring (heal) is drunk from in the bell tower; anyone who
## walked past it still has it after the bell, so nothing later is out of reach.
func _finish() -> void:
	if kind == "bell":
		GameState.grant_ability("heal")
	elif kind == "stillness":
		# Wren has something else to say, back in the Eye
		GameState.set_flag("eye.stillness_seen")
	elif kind == "sky":
		GameState.set_flag("eye.complete")
		GameState.set_flag("game.complete")
		GameState.save_game()
	super()


# ------------------------------------------------------------------ the Long Stair

## The Landing: five doors in a wall, a bell-light over each (the first
## `lit` of them lit), Echidna standing before them, in the dark.
func _landing_picture(p: Node2D, lit: int) -> void:
	var c := _canvas(p)
	_brick_wall(c, 0.3)
	SurfaceArt.ground(c, -176, 560, 150, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9).modulate = Color(0.45, 0.46, 0.6)
	StoryStage.fog(p, Rect2(-300, 400, 1750, 170), Color(0.45, 0.55, 0.78, 0.26), 0.01, 0.2)
	var tints := [Color(1.0, 0.7, 0.4), Color(0.5, 0.8, 1.0), Color(1.0, 0.92, 0.55), Color(0.8, 0.65, 1.0), Color(1.0, 1.0, 1.0)]
	for i in 5:
		var x := 52.0 + i * 66.0
		var door := SurfaceArt.animated(c, "door_nan", Vector2(x, 150), 0.0, 1.0)
		door.stop()
		door.frame = 0
		door.modulate = Color(0.6, 0.62, 0.78) if i < 4 else Color(0.5, 0.5, 0.6)
		var bell := _put(c, "shrine_bell", Vector2(x, 108))
		if i < lit and i < 4 or lit >= 5:
			bell.modulate = tints[i]
			StoryPaint.glow(c, Vector2(x, 100), 14.0, tints[i], 0.8)
		else:
			bell.modulate = Color(0.25, 0.25, 0.32)
	var echidna := AnimatedSprite2D.new()
	echidna.sprite_frames = ECHIDNA
	echidna.offset = ECHIDNA.get_meta(&"sprite_offset", Vector2(0, -32))
	echidna.scale = Vector2.ONE * (0.812 / SurfaceArt.LANE_SCALE)
	echidna.position = Vector2(22, 150)
	c.add_child(echidna)
	echidna.play(&"idle")
	if lit >= 5:
		StoryPaint.glow(c, Vector2(52.0 + 4 * 66.0, 120), 40.0, Color(1.0, 1.0, 1.0), 0.9)


## The Landing on arrival: five doors rimed with frost, but the first one is
## warm (a glow under it), and chalk footprints lead to it.
func _landing_arrival(p: Node2D) -> void:
	_landing_picture(p, 0)
	var c: Node2D = p.get_node("Canvas")
	for i in range(1, 5):
		var rime := _put(c, "door_frost", Vector2(52.0 + i * 66.0, 150))
		rime.modulate = Color(1, 1, 1, 0.95)
	var warm := StoryPaint.glow(c, Vector2(52.0, 146), 26.0, Color(1.0, 0.6, 0.3), 1.0)
	warm.modulate.a = 0.0
	for k in 3:
		_put(c, "chalk_steps", Vector2(20.0 + k * 10.0, 151)).modulate = Color(1, 1, 1, 0.9)
	_cues[1] = func() -> void:
		var t := p.create_tween()
		t.tween_property(warm, "modulate:a", 1.0, 2.0)


# ------------------------------------------------------------------ the Rewritten Sky

## The good ending, the story's centrepiece: the cube takes Light, Beam, Up,
## Long; the four chains break one word at a time; the moth fills with light;
## Wren comes to her mother; the candle goes out; they rise as two new stars
## where the dark gap was; the Hush thaws and the snow falls; Lowbell's colour
## and chimes come back; Nan says Echidna's name; and the promise from the
## cottage is kept.
func _sky_pictures() -> Array:
	var warm := {"light": Color(1.06, 0.96, 0.84), "saturation": 0.95, "vignette": 0.55}
	var night := {"shadow": Color(0.02, 0.03, 0.08), "saturation": 0.8, "vignette": 0.65}
	return [
		{"era": "THE REWRITTEN SKY", "lines": ["", ""], "build": _sky_cube_wakes,
			"zoom": [1.0, 1.07], "from": Vector2(0, 24), "to": Vector2(0, -12), "min": [4.8, 4.2]},
		{"lines": [""], "build": _sky_chains_break, "music": "ending_swell.wav", "music_db": -3.0,
			"zoom": [1.04, 1.0], "from": Vector2(0, 30), "to": Vector2(0, -10), "min": [7.6]},
		{"lines": [""], "build": _sky_moth_alight, "grade": {"light": Color(1.04, 0.98, 0.9), "saturation": 0.7, "vignette": 0.6},
			"zoom": [1.1, 1.0], "from": Vector2(0, 50), "to": Vector2(0, -24), "min": [8.0]},
		{"lines": [{"who": "wren", "face": "smile", "text": "I'm awake, Mum. It's morning."}, {"who": "ilse", "face": "grief", "text": "I know. I know, love."},
				{"who": "wren", "face": "calm", "text": "Come with me. You won't be alone."}, ""],
			"build": _sky_bedside, "grade": warm,
			"zoom": [1.0, 1.06], "from": Vector2(-10, 0), "to": Vector2(10, -6), "min": [5.6, 4.6, 6.0, 4.2]},
		{"lines": [""], "build": _sky_rising, "grade": warm,
			"zoom": [1.0, 1.04], "from": Vector2(0, 60), "to": Vector2(0, -50), "min": [7.6]},
		{"card": true, "lines": ["What cannot be kept can be sent.\n\n— carved over the door of the Eye"], "min": [5.6]},
		{"lines": ["Where the dark had been, two new stars came out, side by side."], "build": _sky_two_stars, "grade": night,
			"zoom": [1.0, 1.08], "from": Vector2(0, 30), "to": Vector2(0, -20), "min": [8.4]},
		{"lines": ["The Hush thawed. For the first time in sixty years, the snow fell."], "build": _sky_thaw,
			"zoom": [1.0, 1.04], "from": Vector2(20, 0), "to": Vector2(-10, 0), "min": [9.0]},
		{"era": "THE BELFRY", "lines": ["Up on the mountain, the great bell hung still. It would never need to ring again."], "build": _sky_silent_bell, "grade": night,
			"zoom": [1.04, 1.0], "from": Vector2(0, -16), "to": Vector2(0, 8), "min": [6.4]},
		{"era": "LOWBELL", "lines": ["In Lowbell the wind came back. The porch chimes moved for the first time in years, and the colour came back into the houses."], "build": _sky_lowbell,
			"zoom": [1.0, 1.06], "from": Vector2(0, -16), "to": Vector2(-16, 12), "min": [6.8]},
		{"lines": ["Nan looked up from her chair.", {"who": "nan", "face": "bright", "text": "Echidna."}, {"who": "nan", "face": "warm", "text": "I'll lose it again one day, love."},
				{"who": "echidna", "face": "neutral", "text": "Then I'll tell you again. As many times as it takes."}],
			"build": _sky_porch, "music": "lullaby.wav", "music_db": -6.0, "grade": night,
			"zoom": [1.3, 1.38], "from": Vector2(-16, 92), "to": Vector2(-24, 98), "min": [3.6, 4.4, 5.0, 6.4]},
		{"lines": [""], "build": _sky_last, "grade": night,
			"zoom": [1.0, 1.12], "from": Vector2(0, 40), "to": Vector2(0, -40), "hold": 0.6, "min": [9.0]},
	]


## The cube takes the four words, one at a time, and a beam rises from it
## into the moth.
func _sky_cube_wakes(p: Node2D) -> void:
	var room := _eye_room(p, 0.0)
	var cube: StoryNodes.Cube = room["cube"]
	var moth: StoryStage.Moth = room["moth"]
	var beam := StoryStage.Beam.new()
	beam.position = cube.position - Vector2(0, 51)
	beam.length = 300.0
	beam.width_near = 70.0
	beam.width_far = 150.0
	beam.reach = 0.0
	p.add_child(beam)
	p.move_child(beam, moth.get_index())
	_cues[0] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.6)
		for i in 4:
			t.tween_callback(Sfx.play.bind("rune_activate", null, -9.0, 0.03))
			t.tween_property(cube, "lit", float(i + 1), 0.55)
			t.tween_interval(0.25)
	_cues[1] = func() -> void:
		Sfx.play("beam_on", null, -8.0, 0.0)
		var t := p.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(beam, "reach", 1.0, 2.2)
		t.tween_property(moth, "light", 0.45, 3.6).set_delay(1.0)


## Close on the plinth: the four chains break, Ice, Freeze, Self, Persist.
func _sky_chains_break(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.4, "Far")
	StoryStage.fill(far, Color("05070e"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("1a1c2c"), Color(0.02, 0.03, 0.06, 0.0))
	var fc := StoryStage.canvas(far, 3.0)
	StoryStage.piece(fc, "hk_stalactites", Vector2(80, 40), Color(0.3, 0.32, 0.42))
	StoryStage.piece(fc, "hk_stalactites", Vector2(300, 44), Color(0.3, 0.32, 0.42), true)
	var hang := StoryStage.layer(p, 0.75, "Moth")
	var moth := StoryStage.Moth.new()
	moth.art_scale = 4.0
	moth.position = Vector2(576, -30)
	moth.light = 0.45
	hang.add_child(moth)
	var c := StoryStage.canvas(p, 4.5)
	var floor_tiles := SurfaceArt.ground(c, -120, 380, 124, 1.0, 4, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
	floor_tiles.modulate = Color(0.3, 0.32, 0.44)
	var chains: Array = []
	var tops := [Vector2(240, -60), Vector2(420, -80), Vector2(732, -80), Vector2(912, -60)]
	var feet := [Vector2(472, 556), Vector2(534, 560), Vector2(618, 560), Vector2(680, 556)]
	for i in 4:
		var chain := StoryStage.Chain.new()
		chain.word = i
		chain.art_scale = 4.0
		chain.position = tops[i]
		chain.to = feet[i] - tops[i]
		chain.plate_at = 0.5
		p.add_child(chain)
		chains.append(chain)
	for k in 2:
		_put(c, "slab", Vector2(128, 124 - k * 8)).modulate = Color(0.5, 0.52, 0.66)
	var cube := StoryNodes.Cube.new()
	cube.sprite_name = "rune_cube_great"
	cube.art_scale = 4.5
	cube.position = Vector2(576, 108 * 4.5 - 76.0)
	cube.words = [&"light", &"beam", &"up", &"long"]
	cube.color = Color(1.0, 0.82, 0.5)
	cube.show_names = true
	cube.lit = 4.0
	p.add_child(cube)
	var beam := StoryStage.Beam.new()
	beam.position = cube.position - Vector2(0, 76)
	beam.length = 520.0
	beam.width_near = 100.0
	beam.width_far = 220.0
	p.add_child(beam)
	StoryStage.embers(p, Rect2(470, 200, 212, 300), Color(1.0, 0.82, 0.55, 0.8), 24, 22.0)
	StoryStage.fog(p, Rect2(-300, 440, 1750, 170), Color(0.45, 0.52, 0.72, 0.3), 0.012, 0.6)
	StoryStage.hanging_snow(p, Rect2(-100, -20, 1352, 620), 80)
	var near := StoryStage.layer(p, 1.45, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_pillar", Vector2(14, 216), Color(0.42, 0.42, 0.52))
	StoryStage.piece(nc, "hk_pillar", Vector2(372, 214), Color(0.42, 0.42, 0.52), true)
	StoryStage.piece(nc, "hk_rocks", Vector2(30, 240), Color(0.4, 0.4, 0.5))
	_cues[0] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.9)
		for i in 4:
			var chain: StoryStage.Chain = chains[i]
			t.tween_callback(func() -> void:
				chain.snap()
				Sfx.play("ice_crack", null, -6.0, 0.08)
				Sfx.play("rune_deactivate", null, -10.0, 0.0))
			t.tween_property(moth, "light", 0.45 + (i + 1) * 0.12, 0.4)
			t.tween_interval(1.1)


## The moth fills with light, and Echidna, small before it, looks up.
func _sky_moth_alight(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.3, "Far")
	StoryStage.fill(far, Color("07060a"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("1d1626"), Color(0.03, 0.03, 0.05, 0.0))
	var fc := StoryStage.canvas(far, 3.0)
	StoryStage.piece(fc, "hk_stalactites", Vector2(60, 46), Color(0.26, 0.24, 0.3))
	StoryStage.piece(fc, "hk_stalactites", Vector2(320, 50), Color(0.26, 0.24, 0.3), true)
	var hang := StoryStage.layer(p, 0.85, "Moth")
	var moth := StoryStage.Moth.new()
	moth.art_scale = 3.3
	moth.position = Vector2(576, 270)
	moth.light = 0.95
	hang.add_child(moth)
	var embers := StoryStage.embers(p, Rect2(160, 160, 832, 420), Color(1.0, 0.8, 0.5, 0.9), 40, 26.0)
	embers.modulate.a = 0.3
	var echidna := _echidna(p, Vector2(520, 566), 1.6)
	echidna.modulate = Color(0.1, 0.09, 0.13)
	var near := StoryStage.layer(p, 1.5, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_rocks", Vector2(40, 238), Color(0.3, 0.28, 0.34))
	StoryStage.piece(nc, "hk_rocks", Vector2(350, 236), Color(0.3, 0.28, 0.34), true)
	StoryStage.piece(nc, "hk_crystals", Vector2(96, 230), Color(0.25, 0.24, 0.3))
	_cues[0] = func() -> void:
		var t := p.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.tween_property(moth, "light", 2.0, 6.0).set_delay(0.6)
		t.tween_property(embers, "modulate:a", 1.0, 5.0).set_delay(0.6)
		t.tween_callback(Sfx.play.bind("heal_done", null, -10.0, 0.0)).set_delay(5.0)


## At the bedside: Wren, awake, comes to her mother; the candle goes out; Ilse
## opens her hand and takes Wren's; and the light takes them both.
func _sky_bedside(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.4, "Far")
	StoryStage.fill(far, Color("0a0810"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("2a2030"), Color(0.03, 0.03, 0.05, 0.0))
	var fc := StoryStage.canvas(far, 4.0)
	StoryStage.piece(fc, "hk_arch", Vector2(150, 146), Color(0.3, 0.27, 0.34))
	var c := StoryStage.canvas(p, 5.0)
	var floor_tiles := SurfaceArt.ground(c, -60, 300, 104, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 13)
	floor_tiles.modulate = Color(0.42, 0.38, 0.45)
	var light_down := StoryStage.Beam.new()
	light_down.up = false
	light_down.position = Vector2(640, -40)
	light_down.length = 600.0
	light_down.width_near = 160.0
	light_down.width_far = 420.0
	light_down.intensity = 0.35
	p.add_child(light_down)
	var bed := SurfaceArt.animated(c, "wren_bed", Vector2(133, 104), 0.9, 1.0)
	bed.modulate = Color(0.95, 0.9, 0.9)
	_put(c, "crate", Vector2(184, 104)).modulate = Color(0.75, 0.7, 0.72)
	var candle := SurfaceArt.animated(c, "candle", Vector2(184, 90), 5.0, 1.0)
	var candle_glow := StoryPaint.glow(c, Vector2(184, 80), 22.0, Color(1.0, 0.72, 0.4), 0.9)
	var ilse := SurfaceArt.animated(c, "hk_ilse_kneel", Vector2(100, 104), 0.0, 1.0)
	ilse.stop()
	ilse.frame = 0
	var wren := SurfaceArt.animated(c, "wren", Vector2(72, 104), 0.0, 1.0)
	wren.stop()
	wren.modulate = Color(1.2, 1.15, 1.05, 0.0)
	var wren_glow := StoryPaint.glow(c, Vector2(72, 94), 18.0, Color(1.0, 0.92, 0.75), 0.7)
	wren_glow.modulate.a = 0.0
	var white := StoryPaint.glow(p, Vector2(470, 440), 520.0, Color(1.0, 0.92, 0.78), 1.4)
	white.modulate.a = 0.0
	StoryStage.embers(p, Rect2(200, 120, 760, 420), Color(1.0, 0.85, 0.6, 0.7), 22, 14.0)
	var near := StoryStage.layer(p, 1.4, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_pillar", Vector2(4, 214), Color(0.32, 0.3, 0.36))
	_cues[0] = func() -> void:
		var t := p.create_tween().set_parallel()
		t.tween_property(wren, "modulate:a", 0.95, 1.6)
		t.tween_property(wren_glow, "modulate:a", 1.0, 1.6)
		t.tween_callback(func(): ilse.frame = 1).set_delay(2.2)
	# Ilse, for the first time, looks up
	_cues[1] = func() -> void:
		ilse.frame = 1
	_cues[2] = func() -> void:
		var t := p.create_tween().set_parallel()
		t.tween_callback(func(): ilse.frame = 2).set_delay(1.6)
		# the candle that kept the night goes out
		t.tween_callback(func(): candle.stop()).set_delay(3.2)
		t.tween_property(candle, "modulate:a", 0.0, 1.0).set_delay(3.2)
		t.tween_property(candle_glow, "modulate:a", 0.0, 1.2).set_delay(3.2)
		t.tween_property(light_down, "intensity", 0.55, 3.0).set_delay(2.6)
	_cues[3] = func() -> void:
		var t := p.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.tween_property(white, "modulate:a", 1.0, 3.6)
		t.tween_property(ilse, "modulate", Color(2.0, 1.9, 1.7, 0.0), 3.2).set_delay(0.6)
		t.tween_property(wren, "modulate", Color(2.0, 1.9, 1.7, 0.0), 3.2).set_delay(0.6)


## The moth rises through the dome, and at the top it comes apart into
## light; two sparks go on up into the night.
func _sky_rising(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.2, "Sky")
	StoryStage.fill(far, SKY_TOP)
	var sc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 260)
	stars.count = 140
	stars.seed_value = 77
	sc.add_child(stars)
	var moth := StoryStage.Moth.new()
	moth.art_scale = 2.2
	moth.position = Vector2(576, 700)
	moth.light = 2.0
	moth.breathe = 1.0
	p.add_child(moth)
	var sparks: Array = []
	for dx in [-10.0, 10.0]:
		var s := StoryPaint.glow(p, Vector2(576 + dx, 690), 26.0, Color(1.0, 0.95, 0.85), 1.4)
		s.modulate.a = 0.0
		sparks.append(s)
	var trail := StoryStage.embers(moth, Rect2(-120, -40, 240, 120), Color(1.0, 0.82, 0.55, 0.9), 30, 30.0)
	trail.local_coords = false
	var near := StoryStage.layer(p, 1.25, "Dome")
	var nc := StoryStage.canvas(near, 3.6)
	StoryStage.piece(nc, "hk_dome", Vector2(160, 172), Color(0.22, 0.22, 0.3))
	_cues[0] = func() -> void:
		var t := p.create_tween().set_trans(Tween.TRANS_SINE)
		t.tween_property(moth, "position:y", 250.0, 4.0).set_ease(Tween.EASE_OUT)
		t.tween_callback(Sfx.play.bind("wisp_arrive", null, -6.0, 0.0))
		t.set_parallel()
		t.tween_property(moth, "modulate", Color(2.0, 1.8, 1.5, 0.0), 1.4)
		for s in sparks:
			t.tween_property(s, "position:y", 262.0, 0.01)
			t.tween_property(s, "modulate:a", 1.0, 0.6)
		t.chain().set_parallel()
		for s in sparks:
			t.tween_property(s, "position:y", 150.0, 3.2).set_ease(Tween.EASE_OUT)


## The night over the mountain: where four stars were dark, two new ones.
func _sky_two_stars(p: Node2D) -> void:
	var sky := _mountain_night(p)
	var pair: Array = sky["pair"]
	for s in pair:
		s.modulate.a = 0.0
	var line: StoryNodes.Constellation = sky["line"]
	line.progress = 0.0
	var rising: Array = []
	for i in 2:
		var spark := StoryPaint.glow(p, Vector2(576 + (i * 2 - 1) * 8, 300), 18.0, Color(1.0, 0.95, 0.85), 1.2)
		spark.modulate.a = 0.0
		rising.append(spark)
	_cues[0] = func() -> void:
		var t := p.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		for i in 2:
			var target: Vector2 = pair[i].global_position
			t.tween_property(rising[i], "modulate:a", 1.0, 0.5).set_delay(0.4)
			t.tween_property(rising[i], "global_position", target, 3.2).set_delay(0.4)
			t.tween_property(rising[i], "modulate:a", 0.0, 0.8).set_delay(3.4)
			t.tween_property(pair[i], "modulate:a", 1.0, 1.4).set_delay(3.2)
		for dead in sky["dead"]:
			t.tween_property(dead, "modulate:a", 0.0, 1.5).set_delay(2.8)
		t.tween_callback(Sfx.play.bind("rune_learn", null, -9.0, 0.0)).set_delay(3.4)
		t.tween_property(line, "progress", 1.0, 1.6).set_delay(4.2)


## The land seen wide, grey with the Hush: the colour comes back from the
## mountain outward, and the hanging snow begins to fall.
func _sky_thaw(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.25, "Sky")
	StoryStage.fill(far, SKY_TOP)
	var fc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 190)
	stars.count = 140
	stars.seed_value = 12
	fc.add_child(stars)
	SurfaceArt.sprite(fc, "spark", Vector2(286, 80), 1.4).modulate = Color(1.0, 0.95, 0.85)
	SurfaceArt.sprite(fc, "spark", Vector2(302, 83), 1.4).modulate = Color(1.0, 0.95, 0.85)
	var hills := StoryStage.layer(p, 0.6, "Hills")
	var hc := StoryStage.canvas(hills, 2.0)
	hc.position.y = 60.0
	SurfaceArt.backdrop(hc, "hills", Vector2(250 - 640, -64), 1.0, 640 * 3)
	var woods := StoryStage.layer(p, 0.8, "Woods")
	var wc := StoryStage.canvas(woods, 2.0)
	wc.position.y = 60.0
	SurfaceArt.backdrop(wc, "woods", Vector2(-220 - 640, -40), 1.0, 640 * 3)
	var c := StoryStage.canvas(p, 2.0)
	c.position.y = 60.0
	SurfaceArt.ground(c, -230, 800, 214, 1.0, 8, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b", "dirt_c"], 21)
	for spec in [["house_small", 40.0, [Vector2(38, 46)]], ["house_medium", 118.0, [Vector2(22, 56)]],
			["house_tiny", 180.0, []], ["house_shop", 250.0, [Vector2(61, 66)]], ["house_small", 330.0, [Vector2(38, 46)]]]:
		var house := _put(c, spec[0], Vector2(spec[1], 215))
		var top_left := house.position + house.offset
		for w in spec[2]:
			StoryPaint.glow(c, top_left + w, 12.0, Color(1.0, 0.8, 0.5), 0.7)
	var snow := StoryStage.hanging_snow(p, Rect2(-300, -340, 1752, 1100), 150)
	var near := StoryStage.layer(p, 1.3, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	for x in [-100.0, 100.0, 300.0, 500.0]:
		StoryStage.piece(nc, "hk_grass", Vector2(x, 196), Color(0.3, 0.32, 0.4))
	# The thaw: grey everywhere but a circle round the summit that grows
	var veil_layer := CanvasLayer.new()
	veil_layer.layer = 1
	p.add_child(veil_layer)
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = HUSH_SHADER
	mat.set_shader_parameter("thaw", true)
	veil.material = mat
	veil_layer.add_child(veil)
	var spread := func(r: float) -> void:
		var view := get_viewport().get_visible_rect().size
		var summit: Vector2 = fc.to_global(Vector2(294, 76))
		var on_screen := get_viewport().get_canvas_transform() * summit
		mat.set_shader_parameter("origin", on_screen / view)
		mat.set_shader_parameter("aspect", view.x / view.y)
		mat.set_shader_parameter("radius", r)
	spread.call(0.0)
	_cues[0] = func() -> void:
		var t := p.create_tween().set_parallel()
		t.tween_method(spread, 0.0, 2.6, 8.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(0.6)
		t.tween_property(snow, "speed_scale", 1.0, 4.0).set_delay(1.4)
		t.tween_callback(Sfx.play.bind("ice_melt", null, -10.0, 0.0)).set_delay(0.6)


## Lowbell: grey, then the chimes swing and the colour comes back.
func _sky_lowbell(p: Node2D) -> void:
	var town := _lowbell_wide(p, true, true)
	StoryPaint.snow(p, Rect2(-300, -340, 1752, 1100), 110)
	var grey := Color(0.5, 0.52, 0.6)
	for l in town["layers"]:
		l.modulate = grey
	_cues[0] = func() -> void:
		# the wind is back (no bell: it never needs to ring again)
		Sfx.play("wind_gust", null, -10.0, 0.0)
		var t := p.create_tween().set_parallel()
		for l in town["layers"]:
			t.tween_property(l, "modulate", Color.WHITE, 2.6).set_delay(0.8)


## Nan's cottage door, under the two stars: she looks up, and knows her.
func _sky_porch(p: Node2D) -> void:
	var porch := _porch(p, true)
	StoryPaint.snow(p, Rect2(-300, -340, 1752, 1100), 90).speed_scale = 0.6
	var nan: AnimatedSprite2D = porch["nan"]
	_cues[0] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.5)
		t.tween_callback(func(): nan.frame = 0)


## The last shot: the mountain under the two new stars, the snow falling.
func _sky_last(p: Node2D) -> void:
	_mountain_night(p, true)




# ------------------------------------------------------------------ the Stillness

## The other ending, Echidna's temptation: Ice, Freeze, Self, Large holds
## everything still, so Nan can never forget her name again. Shown with its
## full weight (the world stopped, Nan stopped mid-word), and then Wren:
## “That's what Mum did.” It leads back to the Eye.
func _stillness_pictures() -> Array:
	var still := {"saturation": 0.12, "shadow": Color(0.04, 0.05, 0.08), "light": Color(0.92, 0.96, 1.04), "vignette": 0.7}
	return [
		{"era": "THE STILLNESS", "lines": ["The world went still. The snow stopped in the air. The chimes stopped mid-swing.", ""],
			"build": _still_lowbell, "grade": still,
			"zoom": [1.0, 1.03], "from": Vector2(0, -10), "to": Vector2(-8, 0), "min": [6.0, 3.0]},
		{"lines": ["Nan had looked up to say her name.", {"who": "nan", "face": "lost", "text": "Echi..."},
				"She would never forget it now. She would never finish saying it, either."],
			"build": _still_porch, "grade": still,
			"zoom": [1.3, 1.34], "from": Vector2(-16, 92), "to": Vector2(-20, 94), "min": [3.6, 4.0, 6.0]},
		{"lines": ["A small cold hand took hers.", {"who": "wren", "face": "pleading", "text": "That's what Mum did."}, {"who": "wren", "face": "calm", "text": "It isn't keeping someone. It's only stopping."}],
			"build": _still_wren, "grade": {"saturation": 0.35, "shadow": Color(0.03, 0.04, 0.08), "vignette": 0.7},
			"zoom": [1.0, 1.08], "from": Vector2(0, 10), "to": Vector2(0, -6), "min": [3.6, 4.6, 5.4]},
	]


## Lowbell held still: nothing moves, not even the snow.
func _still_lowbell(p: Node2D) -> void:
	var town := _lowbell_wide(p, false, false)
	var stars: StoryNodes.Stars = town["stars"]
	stars.fade = 0.7
	StoryStage.hanging_snow(p, Rect2(-300, -340, 1752, 1100), 140)


## Nan in her chair, stopped in the middle of Echidna's name.
func _still_porch(p: Node2D) -> void:
	var porch := _porch(p, false)
	(porch["nan"] as AnimatedSprite2D).frame = 0
	(porch["echidna"] as AnimatedSprite2D).stop()
	(porch["stars"] as StoryNodes.Stars).fade = 0.7
	StoryStage.hanging_snow(p, Rect2(-300, -340, 1752, 1100), 110)


## In the Eye: Wren beside Echidna under the frozen moth, holding her hand.
func _still_wren(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.4, "Far")
	StoryStage.fill(far, Color("04060c"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("0e1830"), Color(0.02, 0.03, 0.06, 0.0))
	var hang := StoryStage.layer(p, 0.7, "Moth")
	var moth := StoryStage.Moth.new()
	moth.art_scale = 3.6
	moth.position = Vector2(576, 170)
	moth.modulate = Color(0.75, 0.82, 1.0)
	hang.add_child(moth)
	var c := StoryStage.canvas(p, 5.0)
	var floor_tiles := SurfaceArt.ground(c, -60, 300, 104, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 13)
	floor_tiles.modulate = Color(0.32, 0.35, 0.48)
	_echidna(c, Vector2(108, 104), 0.541, false).stop()
	var wren := SurfaceArt.animated(c, "wren", Vector2(124, 104), 0.0, 1.0, true)
	wren.stop()
	wren.frame = 1
	StoryPaint.glow(c, Vector2(124, 94), 16.0, Color(0.7, 0.85, 1.0), 0.5)
	StoryStage.fog(p, Rect2(-300, 420, 1750, 170), Color(0.45, 0.55, 0.78, 0.3), 0.004, 0.2)
	StoryStage.hanging_snow(p, Rect2(-100, -20, 1352, 620), 110)
	var near := StoryStage.layer(p, 1.4, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_pillar", Vector2(10, 214), Color(0.32, 0.32, 0.4))
	StoryStage.piece(nc, "hk_rocks", Vector2(370, 238), Color(0.3, 0.3, 0.38), true)


# ------------------------------------------------------------------ the bell

## The mountain at night: the bell's four notes go out from the summit in
## rings (in time with the peal that plays with the picture), and the grey
## fog at the mountain's foot draws back.
func _peal_crosses(p: Node2D) -> void:
	var sky := _mountain_night(p, false, false)
	var stars: StoryNodes.Stars = sky["stars"]
	stars.fade = 0.4
	var rings := StoryNodes.Rings.new()
	rings.color = Color(0.85, 0.9, 1.0)
	rings.speed = 300.0
	rings.life = 3.4
	rings.position = Vector2(576, 230)
	p.add_child(rings)
	var hush := StoryStage.fog(p, Rect2(-300, 330, 1750, 300), Color(0.55, 0.57, 0.66, 0.6), 0.006, 0.7)
	var t := p.create_tween()
	t.tween_interval(0.3)
	for k in 5:
		t.tween_callback(func() -> void:
			rings.ring()
			var lift := p.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			lift.tween_property(hush, "position:y", hush.position.y + 40.0, 1.2)
			lift.tween_property(hush, "modulate:a", maxf(hush.modulate.a - 0.16, 0.2), 1.2)
			lift.tween_property(stars, "fade", maxf(stars.fade - 0.1, 0.0), 1.2))
		t.tween_interval(1.6 if k < 3 else 2.1)


## Nan's kitchen at night: the hearth, her chair beside it, the jars on the
## shelf. With `humming` the fire burns and four notes rise from her as she
## hums; on the second line she looks at the door. Otherwise the hearth is
## cold, and on the second line it lights itself.
func _nan_hearth(p: Node2D, humming: bool) -> void:
	var c := StoryStage.canvas(p, 4.0)
	_brick_wall(c, 0.3)
	var floor_tiles := SurfaceArt.ground(c, -110, 400, 130, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 5)
	floor_tiles.modulate = Color(0.45, 0.4, 0.42)
	_put(c, "shelf_jars", Vector2(66, 82)).modulate = Color(0.62, 0.56, 0.6)
	_put(c, "table", Vector2(236, 131)).modulate = Color(0.7, 0.62, 0.62)
	var fire := SurfaceArt.animated(c, "hearth", Vector2(172, 131), 5.0, 1.0)
	var fire_glow := StoryPaint.glow(c, Vector2(172, 116), 50.0, Color(1.0, 0.68, 0.38), 1.0)
	var embers := StoryStage.embers(c, Rect2(160, 96, 24, 20), Color(1.0, 0.7, 0.4, 0.9), 10, 10.0)
	var nan := SurfaceArt.animated(c, "nan_seated", Vector2(128, 131), 0.0, 1.0)
	nan.stop()
	nan.frame = 2
	var near := StoryStage.layer(p, 1.35, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_pillar", Vector2(6, 214), Color(0.26, 0.22, 0.26))
	if humming:
		var notes: Array = []
		for i in 4:
			var note := StoryPaint.glow(c, Vector2(128, 100), 3.0, Color(1.0, 0.86, 0.6), 1.2)
			note.modulate.a = 0.0
			notes.append(note)
		_cues[0] = func() -> void:
			var t := p.create_tween()
			t.tween_interval(1.0)
			for i in 4:
				var note: Sprite2D = notes[i]
				t.tween_callback(func() -> void:
					note.modulate.a = 1.0
					var rise := p.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
					rise.tween_property(note, "position", Vector2(122 + i * 9, 66 - (i % 2) * 5), 2.4)
					rise.tween_property(note, "modulate:a", 0.0, 2.8).set_delay(0.6))
				t.tween_interval(0.9)
		_cues[1] = func() -> void:
			var t := p.create_tween()
			t.tween_interval(0.8)
			t.tween_callback(func(): nan.frame = 0)
	else:
		# Cold: the Hush's pale flame, no warmth in it
		fire.modulate = Color(0.45, 0.5, 0.66)
		fire_glow.modulate.a = 0.0
		embers.emitting = false
		_cues[1] = func() -> void:
			var t := p.create_tween().set_parallel()
			t.tween_callback(Sfx.play.bind("brazier_ignite", null, -8.0, 0.0)).set_delay(0.6)
			t.tween_property(fire, "modulate", Color(1.25, 1.0, 0.85), 1.4).set_delay(0.6)
			t.tween_property(fire_glow, "modulate:a", 1.0, 1.6).set_delay(0.6)
			t.tween_callback(func(): embers.emitting = true).set_delay(0.8)
			t.tween_callback(func(): nan.frame = 0).set_delay(2.4)


## The cracked bell, and the stair above it: on the second line a small chalk
## star shows on the wall, glowing faintly.
func _chalk_star_stair(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.45, "Far")
	StoryStage.fill(far, Color("05060c"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("141a30"), Color(0.02, 0.03, 0.06, 0.0))
	var c := StoryStage.canvas(p, 3.0)
	_brick_wall(c, 0.3)
	var floor_tiles := SurfaceArt.ground(c, -176, 560, 150, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
	floor_tiles.modulate = Color(0.36, 0.38, 0.52)
	var hang := _bell_frame(c, 150.0, 150.0)
	hang.modulate = Color(0.55, 0.56, 0.68)
	(hang.get_child(0) as AnimatedSprite2D).frame = 1
	var swing := p.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_property(hang, "rotation", 0.04, 1.6)
	swing.tween_property(hang, "rotation", -0.04, 1.6)
	for i in 5:
		SurfaceArt.tile_row(c, Vector2(250 + i * 16, 150 - i * 16), ["slab_a", "slab_b"], 1.0).modulate = Color(0.45, 0.47, 0.6)
	var star := _put(c, "chalk_star", Vector2(262, 84))
	star.scale = Vector2(1.6, 1.6)
	star.modulate.a = 0.0
	var star_glow := StoryPaint.glow(c, Vector2(262, 75), 16.0, Color(0.85, 0.92, 1.0), 0.9)
	star_glow.modulate.a = 0.0
	StoryStage.hanging_snow(p, Rect2(-100, -20, 1352, 620), 50).speed_scale = 0.15
	var near := StoryStage.layer(p, 1.4, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_pillar", Vector2(4, 214), Color(0.3, 0.3, 0.38))
	_cues[2] = func() -> void:
		var t := p.create_tween().set_parallel()
		t.tween_property(star, "modulate:a", 1.0, 2.0).set_delay(1.0)
		t.tween_property(star_glow, "modulate:a", 1.0, 2.0).set_delay(1.0)
		t.tween_callback(Sfx.play.bind("hint", null, -12.0, 0.0)).set_delay(1.4)


# ------------------------------------------------------------------ the dome

## Under the opened dome: the stars, and Echidna small below them; on the
## second line four stars show dark, and the dark spells the sentence.
func _dome_gap(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.2, "Sky")
	StoryStage.fill(far, SKY_TOP)
	StoryStage.wash(far, Rect2(-420, 200, 1992, 760), Color(0.04, 0.05, 0.12, 0.0), Color("2a3560"))
	var sc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 280)
	stars.count = 180
	stars.seed_value = 77
	sc.add_child(stars)
	var words := [[&"ice", "ICE"], [&"freeze", "FREEZE"], [&"self", "SELF"], [&"persist", "PERSIST"]]
	var dark: Array = []
	for i in words.size():
		var g := StoryNodes.Glyph.new()
		g.glyph = words[i][0]
		g.label = words[i][1]
		g.size = 46.0
		g.color = Color(0.45, 0.4, 0.62)
		g.position = Vector2(480 + i * 124, 170 + (i % 2) * 36)
		g.alpha = 0.0
		far.add_child(g)
		dark.append(g)
	var near := StoryStage.layer(p, 1.25, "Dome")
	var nc := StoryStage.canvas(near, 3.6)
	StoryStage.piece(nc, "hk_dome", Vector2(160, 200), Color(0.2, 0.2, 0.28))
	var c := StoryStage.canvas(p, 3.0)
	var ledge := SurfaceArt.ground(c, -176, 560, 180, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 4)
	ledge.modulate = Color(0.18, 0.18, 0.26)
	var echidna := _echidna(c, Vector2(192, 180), 0.541)
	echidna.modulate = Color(0.2, 0.2, 0.28)
	_cues[1] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.6)
		for g in dark:
			t.tween_callback(Sfx.play.bind("rune_deactivate", null, -12.0, 0.0))
			t.tween_property(g, "alpha", 1.0, 0.8)


## The view through the lens: the Eye far below, frosted over; the held
## moment folded tight over the cube in its chains; Ilse kneeling at the bed.
func _lens_view(p: Node2D) -> void:
	_eye_room(p, 0.0, [&"ice", &"freeze", &"self", &"persist"], true, false)


# ------------------------------------------------------------------ the wings

## Behind the last door of the Galleries: a dark arch with warm light in it,
## and Wren, small, standing in the light.
func _wren_door(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.4, "Far")
	StoryStage.fill(far, Color("07060a"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("1b1626"), Color(0.03, 0.03, 0.05, 0.0))
	var c := StoryStage.canvas(p, 4.0)
	_brick_wall(c, 0.26)
	var floor_tiles := SurfaceArt.ground(c, -110, 400, 130, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 3)
	floor_tiles.modulate = Color(0.32, 0.3, 0.38)
	StoryPaint.glow(c, Vector2(144, 100), 44.0, Color(1.0, 0.8, 0.52), 0.9)
	var inside := StoryStage.Beam.new()
	inside.up = false
	inside.position = Vector2(576, 90)
	inside.length = 440.0
	inside.width_near = 90.0
	inside.width_far = 170.0
	inside.intensity = 0.4
	p.add_child(inside)
	StoryStage.piece(c, "hk_arch", Vector2(144, 131), Color(0.32, 0.28, 0.34))
	var wren := SurfaceArt.animated(c, "wren", Vector2(144, 131), 0.0, 1.0)
	wren.stop()
	var near := StoryStage.layer(p, 1.4, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_pillar", Vector2(30, 214), Color(0.24, 0.22, 0.28))
	StoryStage.piece(nc, "hk_pillar", Vector2(356, 212), Color(0.24, 0.22, 0.28), true)
	_cues[1] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(0.8)
		t.tween_callback(func(): wren.frame = 1)


## Lowbell: Nan alone on her porch at night, humming.
func _porch_hum(p: Node2D) -> void:
	var porch := _porch(p, false)
	(porch["echidna"] as AnimatedSprite2D).visible = false
	var nan: AnimatedSprite2D = porch["nan"]
	var c: Node2D = nan.get_parent()
	var t := p.create_tween()
	t.tween_interval(1.4)
	for i in 4:
		var note := StoryPaint.glow(c, Vector2(118, 104), 3.0, Color(1.0, 0.86, 0.6), 1.2)
		note.modulate.a = 0.0
		t.tween_callback(func() -> void:
			note.modulate.a = 1.0
			var rise := p.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			rise.tween_property(note, "position", Vector2(112 + i * 9, 74 - (i % 2) * 5), 2.4)
			rise.tween_property(note, "modulate:a", 0.0, 2.8).set_delay(0.6))
		t.tween_interval(0.9)


## Down into the Eye: a stair falling away into the dark, Echidna small on
## it, and the folded moth vast beside her, breathing.
func _descent(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.35, "Far")
	StoryStage.fill(far, Color("04060c"))
	StoryStage.wash(far, Rect2(-420, -320, 1992, 900), Color("0c1428"), Color(0.02, 0.03, 0.06, 0.0))
	var fc := StoryStage.canvas(far, 3.0)
	StoryStage.piece(fc, "hk_stalactites", Vector2(100, 50), Color(0.3, 0.33, 0.46))
	StoryStage.piece(fc, "hk_stalactites", Vector2(330, 54), Color(0.3, 0.33, 0.46), true)
	var hang := StoryStage.layer(p, 0.7, "Moth")
	var moth := StoryStage.Moth.new()
	moth.folded = true
	moth.art_scale = 4.4
	moth.position = Vector2(800, 330)
	moth.modulate = Color(0.85, 0.9, 1.0)
	hang.add_child(moth)
	var c := StoryStage.canvas(p, 3.0)
	for i in 7:
		SurfaceArt.tile_row(c, Vector2(40 + i * 18, 92 + i * 14), ["slab_a", "slab_b"], 1.0).modulate = Color(0.3, 0.32, 0.44)
	var echidna := _echidna(c, Vector2(110, 134), 0.541, true)
	echidna.modulate = Color(0.55, 0.58, 0.72)
	StoryStage.fog(p, Rect2(-300, 440, 1750, 180), Color(0.45, 0.55, 0.78, 0.32), 0.008, 0.5)
	StoryStage.hanging_snow(p, Rect2(-100, -20, 1352, 620), 110)
	var near := StoryStage.layer(p, 1.45, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_rocks", Vector2(30, 238), Color(0.22, 0.22, 0.3))
	StoryStage.piece(nc, "hk_crystals", Vector2(360, 234), Color(0.5, 0.6, 0.8), true)
	StoryPaint.glow(nc, Vector2(360, 210), 26.0, Color(0.45, 0.65, 1.0), 0.5)


## The great bell in its frame on the mountain, hanging still in the falling
## snow, under the two new stars: it never needs to ring again.
func _sky_silent_bell(p: Node2D) -> void:
	var far := StoryStage.layer(p, 0.2, "Sky")
	StoryStage.fill(far, SKY_TOP)
	StoryStage.wash(far, Rect2(-420, 200, 1992, 760), Color(0.04, 0.05, 0.12, 0.0), Color("2a3560"))
	var sc := StoryStage.canvas(far, 2.0)
	var stars := StoryNodes.Stars.new()
	stars.area = Rect2(-220, -170, 1000, 260)
	stars.count = 140
	stars.seed_value = 5
	sc.add_child(stars)
	for at in [Vector2(330, 70), Vector2(346, 73)]:
		SurfaceArt.sprite(sc, "spark", at, 1.6).modulate = Color(1.0, 0.95, 0.85)
		StoryPaint.glow(sc, at - Vector2(0, 3), 8.0, Color(1.0, 0.9, 0.7), 0.8)
	var c := StoryStage.canvas(p, 5.0)
	var ledge := SurfaceArt.ground(c, -90, 330, 96, 1.0, 8, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 51)
	ledge.modulate = Color(0.34, 0.35, 0.48)
	var bell := _bell_frame(c, 115.0, 96.0)
	bell.modulate = Color(0.75, 0.75, 0.86)
	(bell.get_child(0) as AnimatedSprite2D).frame = 1
	StoryPaint.snow(p, Rect2(-300, -340, 1752, 1100), 120).speed_scale = 0.5
	var near := StoryStage.layer(p, 1.35, "Near")
	var nc := StoryStage.canvas(near, 3.0)
	StoryStage.piece(nc, "hk_rocks", Vector2(20, 240), Color(0.2, 0.2, 0.28))
	StoryStage.piece(nc, "hk_rocks", Vector2(372, 242), Color(0.2, 0.2, 0.28), true)
