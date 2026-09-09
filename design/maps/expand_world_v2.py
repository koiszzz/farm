"""Reproducible v2 world layout; preserves the original cultivated cells/save coordinates."""
import json
from pathlib import Path

path = Path(__file__).with_name("outdoor_navigation_v1.json")
data = json.loads(path.read_text(encoding="utf-8"))
farm = next(m for m in data["maps"] if m["id"] == "farm_outdoor")
farm["size_tiles"] = [64, 44]
farm["surfaces"][0]["rect"] = [0, 0, 64, 44]
farm["surfaces"] = [r for r in farm["surfaces"] if not r["id"].startswith("v2_")]
farm["surfaces"] += [
    {"id": "v2_riverside_lane", "class": "path", "points": [[28,14],[42,14],[42,20],[63,20]]},
    {"id": "v2_south_garden_lane", "class": "path", "points": [[17,14],[17,29],[45,29],[45,20]]},
    {"id": "v2_front_porch", "class": "path", "rect": [14,10,3,2]},
]
farm["blocked"] = [r for r in farm["blocked"] if not r["id"].startswith("tree_") and r["id"] != "v2_well"]
farm["blocked"].append({"id": "v2_well", "class": "solid", "rect": [24,8,2,2]})
for i, (x,y) in enumerate([(4,6),(7,8),(34,7),(39,6),(45,8),(52,7),(59,9),(6,30),(11,34),(24,35),(31,33),(39,37),(49,35),(56,31),(60,38)]):
    farm["blocked"].append({"id": f"tree_farm_{i}", "class": "solid", "rect": [x,y,1,1]})
farm["exits"] = [e for e in farm["exits"] if e["id"] != "farm_to_riverside"]
farm["exits"].append({"id": "farm_to_riverside", "class": "exit", "rect": [63,19,1,3], "target": "riverside", "arrival": [2,15]})
river = {
    "id": "riverside", "size_tiles": [48,32], "spawn": [2,15],
    "surfaces": [
        {"id": "river_grass", "class": "grass", "rect": [0,0,48,32]},
        {"id": "river_walk", "class": "path", "rect": [0,14,21,3]},
        {"id": "bank_walk", "class": "path", "rect": [20,7,3,20]},
    ],
    "blocked": [{"id": "river_water", "class": "water", "rect": [24,0,24,32]}],
    "interactions": [],
    "exits": [{"id": "riverside_to_farm", "class": "exit", "rect": [0,14,1,3], "target": "farm_outdoor", "arrival": [62,20]}],
}
for i, (x,y) in enumerate([(3,5),(8,7),(14,5),(17,10),(3,23),(8,27),(15,24),(18,30)]):
    river["blocked"].append({"id": f"tree_river_{i}", "class": "solid", "rect": [x,y,1,1]})
data["maps"] = [m for m in data["maps"] if m["id"] != "riverside"] + [river]
path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
