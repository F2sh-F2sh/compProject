"""Plot observations exported by fit_difficulty.gd; never synthesizes observations."""
import argparse
import csv
from pathlib import Path
import math


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("observations", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    with args.observations.open(encoding="utf-8", newline="") as stream:
        rows = list(csv.DictReader(stream))
    observations = []
    for row in rows:
        try:
            x, y = float(row["r"]), float(row["time"])
        except (KeyError, ValueError):
            continue
        if math.isfinite(x) and math.isfinite(y) and x >= 0 and y >= 0:
            observations.append((x, y, row.get("module", "Unknown")))
    if not observations:
        parser.error("No valid observations; collect playtest solves before plotting.")
    import os
    import sys
    os.environ.setdefault("MPLCONFIGDIR", str(Path(__file__).resolve().parents[1] / ".godot" / "procgen-mpl-cache"))
    local_packages = Path(__file__).resolve().parents[1] / ".godot" / "procgen-python"
    if local_packages.is_dir():
        sys.path.insert(0, str(local_packages))
    try:
        import matplotlib
    except ImportError:
        parser.error("This optional chart tool needs matplotlib: python -m pip install matplotlib")
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, axis = plt.subplots(figsize=(8, 5), layout="constrained")
    for module in sorted({row[2] for row in observations}):
        values = [row for row in observations if row[2] == module]
        axis.scatter([v[0] for v in values], [v[1] for v in values], label=module, alpha=.65, s=20)
    n = len(observations)
    sx = sum(v[0] for v in observations)
    sy = sum(v[1] for v in observations)
    sxx = sum(v[0] ** 2 for v in observations)
    sxy = sum(v[0] * v[1] for v in observations)
    denominator = n * sxx - sx ** 2
    if n >= 3 and abs(denominator) > 1e-8:
        slope = (n * sxy - sx * sy) / denominator
        intercept = (sy - slope * sx) / n
        bounds = [min(v[0] for v in observations), max(v[0] for v in observations)]
        axis.plot(bounds, [intercept + slope * x for x in bounds], color="#44305c", label="Least-squares fit")
    axis.set(xlabel="Predicted difficulty R", ylabel="Observed solve time (seconds)", title=f"Difficulty calibration ({n} recorded solves)")
    axis.grid(alpha=.2)
    axis.legend(fontsize=8, loc="upper left", bbox_to_anchor=(1.01, 1))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(args.output, dpi=180)
    plt.close(fig)
    print(args.output.resolve())


if __name__ == "__main__":
    main()
