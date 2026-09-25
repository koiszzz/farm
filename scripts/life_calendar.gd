class_name LifeCalendar
extends RefCounted

const SEASONS := ["春", "夏", "秋", "冬"]
const WEEKDAYS := ["一", "二", "三", "四", "五", "六", "日"]
const FESTIVALS := [
	{"id": "blossom", "season": 0, "day": 13, "name": "花溪春日会", "activity": "在镇上寻找六朵春日印花，限时完成", "reward": 180},
	{"id": "summer", "season": 1, "day": 14, "name": "夏日分享宴", "activity": "带一份自己种的作物到广场分享", "reward": 240},
	{"id": "harvest", "season": 2, "day": 16, "name": "丰收展", "activity": "带三份自己种的作物参加丰收展", "reward": 400},
	{"id": "winter", "season": 3, "day": 25, "name": "冬星祝福夜", "activity": "与三位居民交换冬日祝福", "reward": 250},
]

static func date(absolute_day: int) -> Dictionary:
	var elapsed := maxi(absolute_day - 1, 0)
	return {"year": elapsed / 112 + 1, "season": (elapsed / 28) % 4, "day": elapsed % 28 + 1, "weekday": elapsed % 7}

static func label(absolute_day: int) -> String:
	var d := date(absolute_day)
	return "第%d年 %s%d日 周%s" % [d.year, SEASONS[d.season], d.day, WEEKDAYS[d.weekday]]

static func festival(absolute_day: int) -> Dictionary:
	var d := date(absolute_day)
	for event in FESTIVALS:
		if event.season == d.season and event.day == d.day:
			return event.duplicate(true)
	return {}

static func weather(absolute_day: int) -> String:
	if not festival(absolute_day).is_empty():
		return "晴"
	var wet := absolute_day % 7 in [3, 6]
	if date(absolute_day).season == 3:
		return "雪" if wet else "晴"
	return "雨" if wet else "晴"
