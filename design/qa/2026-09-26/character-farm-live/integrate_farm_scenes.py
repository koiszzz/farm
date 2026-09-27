import json
import textwrap
from pathlib import Path

path = Path("design/maps/outdoor_navigation_v1.json")
source = path.read_text(encoding="utf-8")
document = json.loads(source)
maps = {entry["id"]: entry for entry in document["maps"]}

farm = maps["farm_outdoor"]
farm["spawn"] = [15, 10]
for entry in farm["objects"]:
    if entry["id"] == "farmhouse":
        entry.update(atlas="farmhouse_front", index=[0, 0], visual_rect=[10, 1, 9, 8])
for entry in farm["blocked"]:
    if entry["id"] == "farmhouse":
        entry["rect"] = [11, 8, 8, 1]
    elif entry["id"] == "v2_well":
        entry["rect"] = [23, 9, 3, 1]

farmhouse = {
    "id": "farmhouse_interior",
    "size_tiles": [20, 12],
    "spawn": [10, 10],
    "surfaces": [{"id": "wood_floor", "class": "path", "rect": [0, 0, 20, 12]}],
    "blocked": [
        {"id": "north_wall", "class": "solid", "rect": [1, 0, 18, 1]},
        {"id": "west_wall", "class": "solid", "rect": [1, 1, 1, 10]},
        {"id": "east_wall", "class": "solid", "rect": [18, 1, 1, 10]},
        {"id": "south_wall_left", "class": "solid", "rect": [2, 11, 7, 1]},
        {"id": "south_wall_right", "class": "solid", "rect": [11, 11, 7, 1]},
        {"id": "bed", "class": "solid", "rect": [3, 5, 2, 1]},
        {"id": "bookshelf", "class": "solid", "rect": [14, 3, 2, 1]},
        {"id": "fireplace", "class": "solid", "rect": [8, 4, 3, 1]},
        {"id": "chest", "class": "solid", "rect": [3, 9, 2, 1]},
        {"id": "plant", "class": "solid", "rect": [15, 9, 1, 1]},
    ],
    "interactions": [
        {"id": "bedside", "class": "interaction", "rect": [5, 6, 1, 1], "target": "bed"},
        {"id": "chest_front", "class": "interaction", "rect": [5, 9, 1, 1], "target": "chest"},
        {"id": "fireplace_front", "class": "interaction", "rect": [9, 5, 1, 1], "target": "fireplace"},
    ],
    "exits": [
        {"id": "farmhouse_to_farm", "class": "exit", "rect": [9, 11, 2, 1], "target": "farm_outdoor", "arrival": [15, 11]}
    ],
    "objects": [
        {"id": "bed", "atlas": "furniture", "index": [0, 0], "visual_rect": [3, 2, 2, 3]},
        {"id": "bookshelf", "atlas": "furniture", "index": [1, 1], "visual_rect": [14, 1, 2, 3]},
        {"id": "fireplace", "atlas": "furniture", "index": [0, 1], "visual_rect": [8, 1, 3, 3]},
        {"id": "chest", "atlas": "furniture", "index": [2, 2], "visual_rect": [3, 8, 2, 2]},
        {"id": "plant", "atlas": "furniture", "index": [3, 1], "visual_rect": [15, 8, 1, 2]},
        {"id": "rug", "atlas": "furniture", "index": [2, 1], "visual_rect": [7, 6, 6, 3], "ground": True},
    ],
}

def replace_map(text, map_id, replacement):
    index = next(i for i, entry in enumerate(document["maps"]) if entry["id"] == map_id)
    next_id = document["maps"][index + 1]["id"]
    start = text.index(f'    {{\n      "id": "{map_id}"')
    end = text.index(f'    {{\n      "id": "{next_id}"', start)
    block = textwrap.indent(json.dumps(replacement, ensure_ascii=False, indent=2), "    ")
    return text[:start] + block + ",\n" + text[end:]


source = replace_map(source, "farm_outdoor", farm)
source = replace_map(source, "farmhouse_interior", farmhouse)
path.write_text(source, encoding="utf-8", newline="\n")
