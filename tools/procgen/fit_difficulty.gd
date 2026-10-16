extends SceneTree

func _initialize() -> void:
	call_deferred("fit")

func fit() -> void:
	var file := ConfigFile.new()
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if args.size() else "user://puzzle_stats.cfg"
	if file.load(path) != OK:
		print("No local solve observations yet: ", path)
		quit(0)
		return
	var script: GDScript = load("res://scripts/daily/daily_calibration.gd")
	var rows: Array = script.read_rows(file)
	var csv_path: String = args[1] if args.size() > 1 else "user://difficulty_observations.csv"
	var csv := FileAccess.open(csv_path, FileAccess.WRITE)
	if csv:
		csv.store_csv_line(PackedStringArray(["module", "tier", "r", "time", "resets", "hints", "deaths"]))
		for row in rows:
			csv.store_csv_line(PackedStringArray([str(row["module"]), str(row["tier"]), str(row["r"]), str(row["time"]), str(row["resets"]), str(row["hints"]), str(row["deaths"])]))
		csv.close()
		print("Local chart observations: ", csv_path)
	else:
		push_warning("Could not write chart observations: " + csv_path)
	var sums := {}
	var sx := 0.0
	var sy := 0.0
	var sxx := 0.0
	var sxy := 0.0
	for row in rows:
		var x := float(row["r"])
		var y := float(row["time"])
		sx += x; sy += y; sxx += x*x; sxy += x*y
		var id := String(row["module"])
		if not sums.has(id): sums[id] = {"n": 0, "time": 0.0, "r": 0.0}
		sums[id]["n"] += 1
		sums[id]["time"] += y
		sums[id]["r"] += x
	for id in sums:
		var mean_time: float = sums[id]["time"] / sums[id]["n"]
		print("%s: n=%d, mean R=%.2f, mean seconds=%.2f, suggested par_seconds=%.0f" % [id, sums[id]["n"], sums[id]["r"] / sums[id]["n"], mean_time, ceil(mean_time)])
	var n := float(rows.size())
	var denominator := n*sxx-sx*sx
	if n < 3 or absf(denominator) < 0.0001:
		print("Need at least three observations with differing R for a fit.")
	else:
		var b := (n*sxy-sx*sy)/denominator
		var a := (sy-b*sx)/n
		print("Least squares: time = %.3f + %.3f * R" % [a,b])
		print("Weight suggestions need independent variation in the five parts; do not infer them from R alone.")
		var features := ["search", "steps", "concept", "execution", "decoys"]
		var matrix: Array = []
		for i in 6:
			var line: Array = []
			for j in 7: line.append(0.0)
			matrix.append(line)
		for row in rows:
			if not row.has("parts"): continue
			var x: Array = [1.0]
			for feature in features: x.append(float(row["parts"].get(feature, 0)))
			for i in 6:
				for j in 6: matrix[i][j] += float(x[i])*float(x[j])
				matrix[i][6] += float(x[i])*float(row["time"])
		# Ridge regularisation keeps sparse observations numerically stable.
		for i in range(1,6): matrix[i][i] += 0.01
		var valid := true
		for i in 6:
			var pivot := i
			for j in range(i+1,6):
				if absf(matrix[j][i]) > absf(matrix[pivot][i]): pivot = j
			var swap: Array = matrix[i]; matrix[i] = matrix[pivot]; matrix[pivot] = swap
			var divisor := float(matrix[i][i])
			if absf(divisor) < 0.00001: valid = false; break
			for j in range(i,7): matrix[i][j] /= divisor
			for k in 6:
				if k == i: continue
				var factor := float(matrix[k][i])
				for j in range(i,7): matrix[k][j] -= factor*float(matrix[i][j])
		if valid:
			var suggestions := {}
			for i in 5: suggestions[features[i]] = snappedf(maxf(0, matrix[i+1][6]), 0.01)
			print("Exploratory part coefficients (seconds per part; validate with a playtest group): ", suggestions)
	quit(0)
