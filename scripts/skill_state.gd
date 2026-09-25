class_name SkillState
extends RefCounted

const ORDER := ["farming", "fishing", "mining", "foraging", "combat"]
const NAMES := {"farming": "耕作", "fishing": "钓鱼", "mining": "采矿", "foraging": "采集", "combat": "战斗"}
const THRESHOLDS := [0, 100, 380, 770, 1300, 2150, 3300, 4800, 6900, 10000, 15000]

var experience := {"farming": 0, "fishing": 0, "mining": 0, "foraging": 0, "combat": 0}


func level(skill: String) -> int:
	if not experience.has(skill): return 0
	var value := int(experience[skill])
	for index in range(THRESHOLDS.size() - 1, -1, -1):
		if value >= THRESHOLDS[index]: return index
	return 0


func gain(skill: String, amount: int) -> Dictionary:
	if not experience.has(skill) or amount <= 0:
		return {"ok": false, "skill": skill, "amount": 0, "old_level": level(skill), "new_level": level(skill)}
	var old_level := level(skill)
	experience[skill] = mini(THRESHOLDS[-1], int(experience[skill]) + amount)
	var new_level := level(skill)
	return {"ok": true, "skill": skill, "amount": amount, "xp": int(experience[skill]), "old_level": old_level, "new_level": new_level, "level_up": new_level > old_level}


func progress(skill: String) -> Dictionary:
	var current_level := level(skill)
	var value := int(experience.get(skill, 0))
	if current_level >= 10:
		return {"level": 10, "xp": value, "current": THRESHOLDS[10], "next": THRESHOLDS[10], "earned": 0, "needed": 0}
	return {"level": current_level, "xp": value, "current": THRESHOLDS[current_level], "next": THRESHOLDS[current_level + 1], "earned": value - THRESHOLDS[current_level], "needed": THRESHOLDS[current_level + 1] - THRESHOLDS[current_level]}


func crop_price_multiplier() -> float:
	return 1.0 + level("farming") * 0.02


func fishing_window_bonus() -> float:
	return level("fishing") * 0.04


func mining_energy_cost() -> int:
	return 1 if level("mining") >= 3 else 2


func forage_amount() -> int:
	return 2 if level("foraging") >= 3 else 1


func combat_damage() -> int:
	return 1 + (1 if level("combat") >= 3 else 0) + (1 if level("combat") >= 7 else 0)


func perk_text(skill: String) -> String:
	match skill:
		"farming": return "作物出货价 +%d%%；2级解锁田园沙拉。" % (level(skill) * 2)
		"fishing": return "追鱼操作条宽度 +%.0f%%；2级解锁海风烤串。" % (fishing_window_bonus() * 30.0)
		"mining": return "%s；2级解锁矿工饭团。" % ("挥镐只消耗1体力" if level(skill) >= 3 else "3级后挥镐只消耗1体力")
		"foraging": return "%s；2级解锁野莓挞。" % ("每次采集获得2份" if level(skill) >= 3 else "3级后每次采集获得2份")
		"combat": return "长剑伤害 %d；3级与7级各提升1点伤害。" % combat_damage()
	return ""


func snapshot() -> Dictionary:
	return {"experience": experience.duplicate()}


func restore(data: Dictionary) -> void:
	for skill in ORDER:
		experience[skill] = clampi(int(data.get("experience", {}).get(skill, 0)), 0, THRESHOLDS[-1])


static func valid(data) -> bool:
	if not data is Dictionary or not data.get("experience", {}) is Dictionary: return false
	for skill in data.experience:
		if skill not in ORDER: return false
		var value = data.experience[skill]
		if (not value is int and not value is float) or not is_finite(float(value)) or float(value) < 0 or float(value) > THRESHOLDS[-1]: return false
	return true
