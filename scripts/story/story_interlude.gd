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
	match kind:
		"kiln":
			return [
				{"era": "FAR BELOW", "lines": ["The Forge Bell rang, and its note ran up and down the mountain.",
						"In Nan's kitchen, the cold stove lit itself. Nan stopped mid-sentence and said half a name: “Ech...” Then it was gone."],
					"build": _chimes_return, "zoom": [1.0, 1.08], "from": Vector2(0, -20), "to": Vector2(-20, 20), "min": [4.6, 6.2]},
				{"era": "THE LANDING", "lines": ["Back on the Landing, small chalk footprints led from the first door to the second.",
						"They stopped at a door with water seeping under it."],
					"build": _landing_picture.bind(1), "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [4.6, 4.6]},
			]
		"cistern":
			return [
				{"era": "THE LANDING", "lines": ["Echidna wrote the Hush's sentence in her notebook: ICE · FREEZE · SELF · PERSIST.",
						"She could already cast two of those four words herself. She closed the notebook."],
					"build": _dome_sky, "zoom": [1.0, 1.1], "from": Vector2(0, 20), "to": Vector2(0, -30), "min": [4.6, 5.0]},
				{"era": "THE LANDING", "lines": ["On the wall, in chalk, a small hand had written a line: “Don't use the last one. —W”"],
					"build": _landing_picture.bind(2), "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [5.5]},
			]
		"lamps":
			return [
				{"era": "SIXTY YEARS AGO", "lines": ["The Prior's memory showed Ilse beside her sleeping daughter's bed. Wren was sick, and the healers had stopped coming.",
						"Ilse could not bear to wait for morning. She cast the spell as a lullaby, and the Hush began to spread like frost."],
					"build": _the_lens, "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(0, 20), "min": [5.5, 6.0]},
				{"era": "THE LANDING", "lines": ["Ilse was not a villain. She was a mother who would not let go."],
					"build": _landing_picture.bind(3), "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [5.0]},
			]
		"galleries":
			return [
				{"era": "THE FOLDED GALLERIES", "lines": ["In the last wing, a small voice spoke through a portal: “Mum won't let go. Please.”",
						"“I want it to end. I just don't want Mum to be alone.”"],
					"build": _thin_bell, "zoom": [1.0, 1.1], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [5.0, 5.0]},
				{"era": "THE LANDING", "lines": ["The Fold Bell rang. All four bell-lights were lit."],
					"build": _landing_picture.bind(4), "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [4.6]},
			]
		"eye":
			return [
				{"era": "THE LANDING", "lines": ["The four bell-lights joined into one beam of light, and the last door opened."],
					"build": _landing_picture.bind(5), "zoom": [1.0, 1.1], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [5.0]},
				{"era": "FAR BELOW", "lines": ["In Lowbell, colour was creeping back into the houses. On her porch, Nan sat humming four notes.",
						"Echidna took a breath and went down into the Eye."],
					"build": _chimes_return, "zoom": [1.0, 1.08], "from": Vector2(0, -20), "to": Vector2(-20, 20), "min": [5.0, 4.6]},
			]
		"stillness":
			return [
				{"era": "THE STILLNESS", "lines": ["The world went silent. The bell, the wind, the falling snow: nothing moved, and nothing ever would.",
						"It was a real ending. But Echidna could not leave it like this. That was not the only sentence."],
					"build": _still_world, "zoom": [1.0, 1.06], "from": Vector2.ZERO, "to": Vector2(0, 10), "min": [5.5, 5.5]},
			]
		"sky":
			return [
				{"era": "THE REWRITTEN SKY", "lines": ["Light rose from the great cube and went up into the empty sky. Wren became a new star, and Ilse let go.",
						"The Hush thawed. For the first time in sixty years, the snow fell."],
					"build": _new_star, "zoom": [1.0, 1.1], "from": Vector2(0, 20), "to": Vector2(0, -30), "min": [5.5, 5.0]},
				{"era": "LOWBELL", "lines": ["In Lowbell, the colour came back with the chimes. On her porch, Nan looked up at the sky and said a name.",
						"“Echidna.”"],
					"build": _chimes_return, "zoom": [1.0, 1.08], "from": Vector2(0, -20), "to": Vector2(-20, 20), "min": [5.5, 4.0]},
			]
	if kind == "dome":
		return [
			{"era": "THE OBSERVATORY", "lines": ["The dome opened, and for the first time in years, Echidna saw the stars.",
					"She read them as she had learned. In the sky, four stars were dark: ICE · FREEZE · SELF · PERSIST."],
				"build": _dome_sky, "zoom": [1.0, 1.1], "from": Vector2(0, 20), "to": Vector2(0, -30), "min": [4.6, 6.0]},
			{"era": "THE OBSERVATORY", "lines": ["Ilse's spell had never stopped. It was written in the sky, and carved far below the mountain.",
					"Through a lens in the floor, Echidna saw a frozen room, deep under the monastery. The only way there was down."],
				"build": _the_lens, "zoom": [1.0, 1.08], "from": Vector2.ZERO, "to": Vector2(0, 20), "min": [5.0, 6.5]},
			{"era": "THE LONG STAIR", "lines": ["Under the lens a stair she had never seen wound down into the mountain: the Long Stair.",
					"At its foot five doors waited, white with the Hush's frost. Only one was warm, and small chalk footprints led to it."],
				"build": _landing_arrival, "zoom": [1.0, 1.08], "from": Vector2(-20, -10), "to": Vector2(10, 10), "min": [5.0, 6.0]},
		]
	return [
		{"era": "FAR BELOW", "lines": ["The great bell rang out over the mountain, and far away in Lowbell, the chimes sounded.",
				"For a moment, the colour came back. In her cottage, Nan lifted her head. “Someone is ringing...”"],
			"build": _chimes_return, "zoom": [1.0, 1.08], "from": Vector2(0, -20), "to": Vector2(-20, 20), "min": [5.0, 6.0]},
		{"era": "THE BELFRY", "lines": ["But the bell was cracked, and its tone was thin. It had pushed the Hush back for a while, not for good.",
				"On the stair above, someone had drawn a small chalk star on the wall. It had not been there before."],
			"build": _thin_bell, "zoom": [1.0, 1.1], "from": Vector2.ZERO, "to": Vector2(10, 10), "min": [5.0, 6.0]},
		{"era": "THE SPRING", "lines": ["At the foot of the stair, the bell's ring shook an old spring loose. It had been dry for nine years, and it began to run.",
				"Running water is the one thing the Hush has never held still. Echidna cupped it in her hands, and a lost word came back: SPRING.",
				InputLabels.format("Stand still and press {heal} to heal yourself. It restores 2 health and costs 20 mana, and a hit breaks it.")],
			"build": _the_spring, "zoom": [1.0, 1.08], "from": Vector2(0, 10), "to": Vector2(0, -10), "min": [5.0, 6.0, 5.5]},
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


## The Spring (heal) comes back with the last picture, however it is left
## (finished, or skipped with Esc); the good ending is saved the same way.
func _finish() -> void:
	if kind == "bell":
		GameState.grant_ability("heal")
	elif kind == "sky":
		GameState.set_flag("eye.complete")
		GameState.set_flag("game.complete")
		GameState.save_game()
	super()


# ------------------------------------------------------------------ the bell

## Lowbell at night, grey, its chimes swinging: and then the colour returns.
func _chimes_return(p: Node2D) -> void:
	var c := _canvas(p, 2.0)
	_night(p, c, Vector2(470, 48), 90, 29)
	SurfaceArt.backdrop(c, "hills", Vector2(-40 - 640, -90), 1.0, 640 * 3)
	var roofs := SurfaceArt.backdrop(c, "town", Vector2(-220 - 640, -100), 1.0, 640 * 3)
	roofs.modulate = Color(0.9, 0.9, 1.0)
	SurfaceArt.ground(c, -230, 800, 210, 1.0, 8, ["grass_a", "grass_b", "grass_c"], ["dirt_a", "dirt_b", "dirt_c"], 61)
	for spec in [["house_small", 34.0, [Vector2(38, 46)]], ["house_medium", 120.0, [Vector2(22, 56)]],
			["house_shop", 236.0, [Vector2(61, 66)]], ["house_big", 368.0, [Vector2(54, 44), Vector2(27, 88)]],
			["house_tower", 470.0, [Vector2(26, 31)]]]:
		var house := _put(c, spec[0], Vector2(spec[1], 212))
		var top_left := house.position + house.offset
		for w in spec[2]:
			StoryPaint.glow(c, top_left + w, 10.0, Color(0.7, 0.84, 1.0), 0.6)
	# The wind chimes, swinging at last
	_put(c, "chime_post", Vector2(303, 211))
	for i in 5:
		var tube := _swaying(c, "chime_tube", Vector2(291 + i * 5.0, 196), 0.18, 40 + i)
		tube.z_index = 1
	var tufts := StoryNodes.Tufts.new()
	tufts.x0 = -220.0
	tufts.x1 = 790.0
	tufts.y = 213.0
	c.add_child(tufts)
	# Grey with the Hush, then the colour comes back for a moment
	p.modulate = Color(0.55, 0.57, 0.66)
	_cues[0] = func() -> void:
		Sfx.play("great_bell", null, -14.0, 0.0)
		var t := p.create_tween()
		t.tween_interval(0.8)
		t.tween_property(p, "modulate", Color.WHITE, 2.2)
	_cues[1] = func() -> void:
		var t := p.create_tween()
		t.tween_interval(3.0)
		t.tween_property(p, "modulate", Color(0.6, 0.62, 0.7), 3.0)


## The bell, cracked, and the chalk star on the wall of the stair above it.
func _thin_bell(p: Node2D) -> void:
	var c := _canvas(p)
	_brick_wall(c, 0.5)
	SurfaceArt.ground(c, -176, 560, 150, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
	var hang := _bell_frame(c, 170.0, 150.0)
	(hang.get_child(0) as AnimatedSprite2D).frame = 1
	var swing := p.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	swing.tween_property(hang, "rotation", 0.04, 1.6)
	swing.tween_property(hang, "rotation", -0.04, 1.6)
	# the stair up, to the right
	for i in 5:
		SurfaceArt.tile_row(c, Vector2(250 + i * 16, 150 - i * 16), ["slab_a", "slab_b"], 1.0)
	var star := _put(c, "spark", Vector2(214, 72))
	star.scale = Vector2(2.4, 2.4)
	star.modulate.a = 0.0
	var star_glow := StoryPaint.glow(c, Vector2(214, 68), 14.0, Color(0.85, 0.92, 1.0), 1.0)
	star_glow.modulate.a = 0.0
	_cues[1] = func() -> void:
		var t := p.create_tween().set_parallel()
		t.tween_property(star, "modulate:a", 1.0, 2.0).set_delay(1.0)
		t.tween_property(star_glow, "modulate:a", 1.0, 2.0).set_delay(1.0)


## The old spring under the belfry, running again, and the word SPRING
## lighting up above it as Echidna remembers it.
func _the_spring(p: Node2D) -> void:
	var c := _canvas(p)
	_brick_wall(c, 0.5)
	SurfaceArt.ground(c, -176, 560, 150, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
	var spring := SurfaceArt.animated(c, "spring", Vector2(212, 150), 6.0, 1.0)
	spring.name = "Spring"
	var echidna := AnimatedSprite2D.new()
	echidna.sprite_frames = ECHIDNA
	echidna.offset = ECHIDNA.get_meta(&"sprite_offset", Vector2(0, -32))
	echidna.scale = Vector2.ONE * (0.812 / SurfaceArt.LANE_SCALE)
	echidna.position = Vector2(150, 150)
	c.add_child(echidna)
	echidna.play(&"idle")
	var glow := StoryPaint.glow(c, Vector2(212, 120), 46.0, Color(0.4, 0.85, 0.95), 1.0)
	glow.modulate.a = 0.0
	StoryPaint.motes(c, Rect2(190, 90, 44, 50), Color(0.55, 0.9, 1.0), 14)
	var word := Label.new()
	word.text = "SPRING"
	word.add_theme_font_override("font", StoryPaint.label_font())
	word.add_theme_font_size_override("font_size", 44)
	word.add_theme_color_override("font_color", Color(0.6, 0.92, 1.0))
	word.modulate.a = 0.0
	word.position = Vector2(470, 120)
	p.add_child(word)
	_cues[0] = func() -> void:
		var t := p.create_tween()
		t.tween_property(glow, "modulate:a", 0.5, 3.0)
	_cues[1] = func() -> void:
		Sfx.play("rune_learn", null, -6.0, 0.0)
		var t := p.create_tween().set_parallel()
		t.tween_property(glow, "modulate:a", 1.0, 1.0)
		t.tween_property(word, "modulate:a", 1.0, 1.2)
		t.tween_property(word, "position:y", 100.0, 3.0)


# ------------------------------------------------------------------ the Long Stair

## The Landing: five doors in a wall, a bell-light over each (the first
## `lit` of them lit), Echidna standing before them.
func _landing_picture(p: Node2D, lit: int) -> void:
	var c := _canvas(p)
	_brick_wall(c, 0.5)
	SurfaceArt.ground(c, -176, 560, 150, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
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


## Snow hanging in the air over a grey, silent world (the Stillness ending).
func _still_world(p: Node2D) -> void:
	var c := _canvas(p)
	_night(p, c, Vector2(318, 38), 0, 5)
	SurfaceArt.ground(c, -176, 560, 150, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
	var echidna := AnimatedSprite2D.new()
	echidna.sprite_frames = ECHIDNA
	echidna.offset = ECHIDNA.get_meta(&"sprite_offset", Vector2(0, -32))
	echidna.scale = Vector2.ONE * (0.812 / SurfaceArt.LANE_SCALE)
	echidna.position = Vector2(192, 150)
	c.add_child(echidna)
	echidna.stop()
	StoryPaint.snow(c, Rect2(60, 0, 260, 150), 60)
	p.modulate = Color(0.55, 0.57, 0.66)


## The stars with one new one among them (the Rewritten Sky ending).
func _new_star(p: Node2D) -> void:
	var c := _canvas(p)
	_night(p, c, Vector2(318, 38), 150, 77)
	SurfaceArt.ground(c, -176, 560, 150, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 4)
	var star := _put(c, "spark", Vector2(192, 60))
	star.scale = Vector2(3.0, 3.0)
	var glow := StoryPaint.glow(c, Vector2(192, 54), 30.0, Color(0.9, 0.95, 1.0), 0.0)
	glow.modulate.a = 0.0
	star.modulate.a = 0.0
	_cues[0] = func() -> void:
		var t := p.create_tween().set_parallel()
		t.tween_property(star, "modulate:a", 1.0, 2.5).set_delay(1.0)
		t.tween_property(glow, "modulate:a", 1.0, 2.5).set_delay(1.0)
	var echidna := AnimatedSprite2D.new()
	echidna.sprite_frames = ECHIDNA
	echidna.offset = ECHIDNA.get_meta(&"sprite_offset", Vector2(0, -32))
	echidna.scale = Vector2.ONE * (0.812 / SurfaceArt.LANE_SCALE)
	echidna.position = Vector2(110, 150)
	c.add_child(echidna)
	echidna.play(&"idle")


# ------------------------------------------------------------------ the dome

## The stars, with four of them dark: the Last Sentence, written in the sky.
func _dome_sky(p: Node2D) -> void:
	var c := _canvas(p)
	_night(p, c, Vector2(318, 38), 150, 77)
	SurfaceArt.ground(c, -176, 560, 142, 1.0, 5, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 4)
	var echidna := AnimatedSprite2D.new()
	echidna.sprite_frames = ECHIDNA
	echidna.offset = ECHIDNA.get_meta(&"sprite_offset", Vector2(0, -32))
	echidna.scale = Vector2.ONE * (0.812 / SurfaceArt.LANE_SCALE)
	echidna.position = Vector2(192, 142)
	c.add_child(echidna)
	echidna.play(&"idle")
	var words := [[&"ice", "ICE"], [&"freeze", "FREEZE"], [&"self", "SELF"], [&"persist", "PERSIST"]]
	_cues[1] = func() -> void:
		var t := p.create_tween()
		for i in words.size():
			var g := StoryNodes.Glyph.new()
			g.glyph = words[i][0]
			g.label = words[i][1]
			g.size = 52.0
			g.color = Color(0.45, 0.4, 0.6)
			g.position = Vector2(330 + i * 150, 150 + (i % 2) * 40)
			g.alpha = 0.0
			p.add_child(g)
			t.tween_callback(Sfx.play.bind("rune_activate", null, -12.0, 0.0))
			t.tween_property(g, "alpha", 1.0, 0.7)


## A round lens in the floor, and in it a frozen room far below.
func _the_lens(p: Node2D) -> void:
	var c := _canvas(p)
	_brick_wall(c, 0.45)
	var lens := _put(c, "win_round_bright", Vector2(192, 112))
	lens.scale = Vector2(7.0, 7.0)
	StoryPaint.glow(c, Vector2(192, 76), 60.0, Color(0.6, 0.78, 1.0), 0.7)
	# what it shows: Wren's bed, Ilse beside it, snow hanging in the air
	var room := Node2D.new()
	room.position = Vector2(192, 100)
	room.modulate = Color(0.75, 0.85, 1.0)
	c.add_child(room)
	_put(room, "wren_bed", Vector2(8, 0), false).scale = Vector2(0.8, 0.8)
	_put(room, "ilse", Vector2(-22, 0)).scale = Vector2(0.8, 0.8)
	StoryPaint.snow(c, Rect2(160, 50, 64, 50), 24)
	SurfaceArt.ground(c, -176, 560, 150, 1.0, 6, ["brick_ledge_a", "brick_ledge_b"], ["bricks_a", "bricks_b"], 9)
