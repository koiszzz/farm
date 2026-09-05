class_name VillageLife
extends RefCounted

const Calendar = preload("res://scripts/life_calendar.gd")
const PEOPLE := {
	"florist": {"name": "小芙", "job": "花店主", "likes": "turnip", "birthday": 9,
		"lines": ["花溪的春天很适合播种，记得每天浇水。", "夏天的花圃真漂亮，不过我最惦记的还是春天的芜菁。", "秋风吹过花店，我正在收集干花。", "冬天地里不能种这些作物，来镇上坐坐吧。"]},
	"shopkeeper": {"name": "阿谷", "job": "杂货店主", "likes": "pumpkin", "birthday": 45,
		"lines": ["防风草四天成熟，芜菁只要三天。柜台有种子。", "今年夏天卖番茄种子，成熟后还能继续结果。", "秋天种南瓜，记得留够七天生长期。", "我冬天照常营业，可以提前准备明年的种子。"]},
	"fisherman": {"name": "老江", "job": "渔夫", "likes": "tomato", "birthday": 76,
		"lines": ["每天来水边聊两句，我就很高兴了。", "雨天不用浇地，正好来看看河水。", "丰收展要带三份作物，别全卖掉了。", "冬星夜要来广场，我有祝福留给你。"]},
}

var bonds: Dictionary = {}
var festival_visits: Dictionary = {}
var claimed: Dictionary = {}

func bond(actor: String) -> Dictionary:
	if not bonds.has(actor):
		bonds[actor] = {"points": 0, "talk_day": 0, "gift_day": 0}
	return bonds[actor]

func talk(actor: String, day: int) -> String:
	if not PEOPLE.has(actor): return "你好。"
	var person: Dictionary = PEOPLE[actor]
	var relation := bond(actor)
	var fresh := int(relation.talk_day) != day
	if fresh:
		relation.talk_day = day
		relation.points = mini(1000, int(relation.points) + 20)
	var event := Calendar.festival(day)
	var line: String = person.lines[Calendar.date(day).season]
	if not event.is_empty():
		var key := str(day)
		if not festival_visits.has(key): festival_visits[key] = []
		if not actor in festival_visits[key]: festival_visits[key].append(actor)
		line = "今天是%s！%s。" % [event.name, event.activity]
	elif (day - 1) % 112 + 1 == int(person.birthday):
		line = "今天是我的生日，能见到你真开心。"
	elif int(relation.points) >= 200:
		line += " 有你这位朋友，花溪镇更热闹了。"
	return "%s · %s\n\n%s\n\n友好度 %d / 1000%s" % [person.name, person.job, line, relation.points, "（今日聊天 +20）" if fresh else "（今天已经聊过了）"]

func gift(actor: String, item: String, farm) -> String:
	if not PEOPLE.has(actor): return "这里没有可以送礼的居民。"
	var relation := bond(actor)
	if int(relation.gift_day) == farm.day: return "今天已经送过礼物，明天再来吧。"
	if farm.get_harvest_count(item) < 1: return "背包没有这份作物。请先收获，或换一份礼物。"
	var person: Dictionary = PEOPLE[actor]
	var points := 60 if person.likes == item else 25
	if (farm.day - 1) % 112 + 1 == int(person.birthday): points *= 3
	farm.harvest_inventory[item] -= 1
	farm.inventory_changed.emit("harvest", item, farm.get_harvest_count(item))
	relation.gift_day = farm.day
	relation.points = mini(1000, int(relation.points) + points)
	return "%s：%s 友好度 +%d。" % [person.name, "这是我最喜欢的，谢谢！" if person.likes == item else "谢谢你的心意！", points]

func join_festival(farm) -> String:
	var event := Calendar.festival(farm.day)
	if event.is_empty(): return "今天没有节日，看看日历准备下一场聚会吧。"
	var key := str(farm.day)
	if claimed.has(key): return "今天已经完成活动并领取奖励，享受节日吧！"
	var required := 0
	if event.id == "summer": required = 1
	if event.id == "harvest": required = 3
	if required == 0 and festival_visits.get(key, []).size() < 3:
		return "请先和广场上的三位居民聊天（%d / 3），再来完成活动。" % festival_visits.get(key, []).size()
	var total := 0
	for item in farm.harvest_inventory: total += farm.get_harvest_count(item)
	if total < required: return "活动需要 %d 份收获的作物，目前有 %d 份。" % [required, total]
	var remaining := required
	for item in farm.harvest_inventory.keys():
		var amount := mini(remaining, farm.get_harvest_count(item))
		farm.harvest_inventory[item] -= amount
		remaining -= amount
		farm.inventory_changed.emit("harvest", item, farm.get_harvest_count(item))
	claimed[key] = true
	farm.gold += int(event.reward)
	farm.gold_changed.emit(farm.gold, int(event.reward))
	for actor in PEOPLE:
		var relation := bond(actor)
		relation.points = mini(1000, int(relation.points) + 40)
	return "%s完成！获得 %d 金币，所有居民友好度 +40。" % [event.name, event.reward]

func snapshot() -> Dictionary:
	return {"bonds": bonds.duplicate(true), "visits": festival_visits.duplicate(true), "claimed": claimed.duplicate(true)}

func restore(data: Dictionary) -> void:
	bonds = data.get("bonds", {}).duplicate(true)
	for relation in bonds.values():
		relation.points = clampi(int(relation.points), 0, 1000)
		relation.talk_day = int(relation.talk_day)
		relation.gift_day = int(relation.gift_day)
	festival_visits = data.get("visits", {}).duplicate(true)
	claimed = data.get("claimed", {}).duplicate(true)
