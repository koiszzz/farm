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
	"mayor": {"name": "林伯", "job": "镇长", "likes": "cauliflower", "birthday": 18,
		"lines": ["镇上的桥和路都要好好照看。", "夏日分享宴需要大家一起准备。", "丰收展是花溪谷最热闹的日子。", "雪后路滑，出门要慢一点。"]},
	"carpenter": {"name": "杉月", "job": "木匠", "likes": "strawberry", "birthday": 34,
		"lines": ["西林里有不少好木材。", "夏天木头干得快，适合修屋顶。", "我在准备冬天要用的柴火。", "雪天工坊里总有木屑的香气。"]},
	"doctor": {"name": "白芷", "job": "医生", "likes": "blueberry", "birthday": 52,
		"lines": ["劳作之后记得休息。", "天气热时要及时补水。", "换季容易疲惫，别把体力耗光。", "冬天也要常出来活动。"]},
	"cook": {"name": "陶乐", "job": "咖啡馆主厨", "likes": "pepper", "birthday": 63,
		"lines": ["春菜最适合清甜的汤。", "辣椒能让夏天更有滋味。", "南瓜派已经放进烤炉啦。", "雪夜来一杯热饮吧。"]},
	"ranger": {"name": "青禾", "job": "护林员", "likes": "cranberry", "birthday": 84,
		"lines": ["溪桥附近刚长出新芽。", "北湖边的树荫很舒服。", "候鸟开始往南飞了。", "雪地上能看到动物的脚印。"]},
	"teacher": {"name": "知夏", "job": "教师", "likes": "melon", "birthday": 97,
		"lines": ["孩子们正在画春天的花。", "暑假也要多读几本书。", "今天课堂上讲了谷物收获。", "冬夜很适合围炉读故事。"]},
	"child": {"name": "豆豆", "job": "学生", "likes": "powdermelon", "birthday": 106,
		"lines": ["我在找最好看的花瓣！", "放学后要去溪边捉虫。", "落叶踩起来沙沙响。", "我想堆一个比镇长还高的雪人！"]},
}

var bonds: Dictionary = {}
var festival_visits: Dictionary = {}
var claimed: Dictionary = {}
var request_days: Dictionary = {}

func activity(actor: String, day: int, minutes: int) -> Dictionary:
	if not Calendar.festival(day).is_empty(): return {"map": "town_square", "label": "参加节日"}
	if minutes >= 1140 or Calendar.weather(day) == "雨": return {"map": "general_store_interior" if actor in ["shopkeeper", "carpenter"] else "cafe_interior", "label": "室内休息"}
	if actor == "shopkeeper" and minutes >= 600 and minutes < 960: return {"map": "general_store_interior", "label": "照看种子铺"}
	if actor == "doctor" and minutes >= 540 and minutes < 1020: return {"map": "clinic_interior", "label": "在诊所值班"}
	if actor == "cook" and minutes >= 600 and minutes < 1140: return {"map": "cafe_interior", "label": "准备餐点"}
	if actor == "carpenter" and minutes >= 480 and minutes < 960: return {"map": "farm_outdoor", "label": "检查农场木料"}
	if actor == "ranger" and minutes >= 480 and minutes < 1080: return {"map": "riverside", "label": "巡视河岸"}
	if actor == "florist" and minutes >= 720 and minutes < 840: return {"map": "cafe_interior", "label": "午间喝茶"}
	if actor == "fisherman" and minutes >= 600 and minutes < 1020: return {"map": "riverside", "label": "河边散步"}
	return {"map": "town_square", "label": "广场散步"}

func request(actor: String, day: int) -> Dictionary:
	if not PEOPLE.has(actor): return {}
	return {"item": ["parsnip", "tomato", "pumpkin", "turnip"][Calendar.date(day).season], "done": int(request_days.get(actor, 0)) == day}

func deliver(actor: String, farm) -> String:
	var wanted := request(actor, farm.day)
	if wanted.is_empty(): return "这里没有这位居民。"
	if wanted.done: return "今天的委托已经完成，明天再来看看吧。"
	if farm.get_harvest_count(wanted.item) < 1: return "背包中还没有委托需要的作物。"
	var crop: Dictionary = farm.get_crop_definition(wanted.item)
	var reward := int(crop.sell_price) * 2 + 20
	farm.harvest_inventory[wanted.item] -= 1
	farm.inventory_changed.emit("harvest", wanted.item, farm.get_harvest_count(wanted.item))
	farm.gold += reward
	farm.gold_changed.emit(farm.gold, reward)
	request_days[actor] = farm.day
	var relation := bond(actor)
	relation.points = mini(1000, int(relation.points) + 40)
	return "谢谢你带来的%s！委托完成：%d 金，友好度 +40。" % [crop.label, reward]

func bond(actor: String) -> Dictionary:
	if not bonds.has(actor):
		bonds[actor] = {"points": 0, "talk_day": 0, "gift_day": 0}
	return bonds[actor]

func talk(actor: String, day: int, minutes := 360) -> String:
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
	else:
		var moments := ["今天想在镇上多走走，看看大家的近况。", "昨晚风吹过窗边，早上醒来特别精神。", "有空带着你家的小狗来玩吧。", "忙完农活也别忘了坐下来歇一歇。"]
		line += " " + str(moments[(day + PEOPLE.keys().find(actor)) % moments.size()])
	line += "\n" + ("下雨了，进屋避避雨吧。" if Calendar.weather(day) == "雨" else "早上好，新的一天开始啦。" if minutes < 600 else "我正%s。" % activity(actor, day, minutes).label)
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
	return {"bonds": bonds.duplicate(true), "visits": festival_visits.duplicate(true), "claimed": claimed.duplicate(true), "request_days": request_days.duplicate()}

func restore(data: Dictionary) -> void:
	bonds = data.get("bonds", {}).duplicate(true)
	for relation in bonds.values():
		relation.points = clampi(int(relation.points), 0, 1000)
		relation.talk_day = int(relation.talk_day)
		relation.gift_day = int(relation.gift_day)
	festival_visits = data.get("visits", {}).duplicate(true)
	claimed = data.get("claimed", {}).duplicate(true)
	request_days = data.get("request_days", {}).duplicate()
