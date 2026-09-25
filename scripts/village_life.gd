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

const GIFT_PREFERENCES := {
	"florist": {"loved": ["strawberry", "apple", "berry_tart"], "liked": ["turnip", "berry", "melon"], "disliked": ["coal", "night_eel"], "hated": ["iron_ore"]},
	"shopkeeper": {"loved": ["pumpkin", "blueberry", "cranberry", "pickles:pumpkin"], "liked": ["turnip", "melon", "egg"], "disliked": ["mushroom", "quartz"], "hated": ["spoiled_vegetable"]},
	"fisherman": {"loved": ["sardine", "night_eel", "shell", "sea_skewer"], "liked": ["tomato", "catfish", "red_snapper", "tuna"], "disliked": ["pumpkin", "cauliflower"], "hated": ["coal"]},
	"mayor": {"loved": ["cauliflower", "quartz", "melon"], "liked": ["pumpkin", "apple", "field_salad"], "disliked": ["berry", "duck_egg"], "hated": ["night_eel"]},
	"carpenter": {"loved": ["wood", "stone", "apple", "cheese"], "liked": ["strawberry", "mushroom", "pumpkin"], "disliked": ["sardine", "shell"], "hated": ["spoiled_vegetable"]},
	"doctor": {"loved": ["field_salad", "mushroom", "milk", "berry_tart"], "liked": ["blueberry", "cauliflower", "sardine"], "disliked": ["pepper", "night_eel"], "hated": ["coal"]},
	"cook": {"loved": ["pepper", "pumpkin_soup", "duck_egg", "milk"], "liked": ["tomato", "pumpkin", "sea_skewer"], "disliked": ["quartz", "iron_ore"], "hated": ["coal"]},
	"ranger": {"loved": ["cranberry", "mushroom", "quartz", "apple"], "liked": ["berry", "wood", "snow_yam"], "disliked": ["pickles:pumpkin", "milk"], "hated": ["spoiled_vegetable"]},
	"teacher": {"loved": ["melon", "cauliflower", "berry_tart"], "liked": ["strawberry", "apple", "field_salad"], "disliked": ["red_snapper", "coal"], "hated": ["night_eel"]},
	"child": {"loved": ["shell", "snow_yam", "duck_egg", "squid"], "liked": ["berry", "strawberry", "powdermelon"], "disliked": ["iron_ore", "quartz"], "hated": ["coal"]},
}

# Conversations use the place the player actually meets a resident. These are
# short scene observations, while the seasonal line and daily schedule remain
# the resident's main dialogue.
const SCENE_BANTER := {
	"farm_outdoor": {
		"florist": ["田边的野花颜色比花圃里的还要鲜亮，记得留几株给蜜蜂。", "看见篱笆边那片小花了吗？农场也能有自己的花园。"],
		"shopkeeper": ["从镇上走来要经过好几块田，看得出你每天都在照料它们。", "出货箱边留条小路吧，收获多的时候搬东西会方便些。"],
		"ranger": ["农场和林地交界处有小动物经过，脚印别被新翻的土盖住。", "靠近树篱的草丛长得快，雨后也许会冒出新的野物。"],
		"child": ["我在你的田埂边数了数，种子发芽时每天都会高一点点！", "这边的稻草人看起来很认真，我给它画了张笑脸。"],
	},
	"town_square": {
		"florist": ["喷泉边种的花要比花圃里耐风，镇上的孩子常来帮我浇水。", "长椅旁的花坛已经冒出新芽，等暖和些我再补几种颜色。"],
		"shopkeeper": ["公告板上常有镇民的消息，买种子之前记得看一眼。", "广场这几条路最近扫得很干净，推货车也不会卡住了。"],
		"mayor": ["从喷泉到公告板的路留宽些，节日时大家都要从这里经过。", "长椅边总有人交换近况，这才是小镇每天热闹起来的原因。"],
		"doctor": ["午后在喷泉边走一圈，对长时间劳作的身体很有好处。", "广场的树荫能挡住正午太阳，记得在这里歇口气。"],
		"teacher": ["我带孩子们数过广场上的石板，他们最喜欢喷泉旁那一圈。", "公告板也是一堂课，孩子们会从镇民的消息里学到互相帮忙。"],
		"child": ["喷泉的水声像在唱歌，我每次都能在这里听出新曲子。", "我和同学约好在长椅旁碰面，看看今天谁先到。"],
		"cook": ["广场上的节日长桌收起来后，我会把木盘带回咖啡馆继续用。", "喷泉边坐一会儿再回厨房，脑子里常会多出一道新菜。"],
		"carpenter": ["长椅的木板有些松了，下次我带工具来给它们加固。", "公告板的屋檐挡雨做得不错，木头边角还可以再磨圆些。"],
	},
	"beach": {
		"fisherman": ["潮池边的水线会告诉你刚才退潮有多快，贝壳常留在湿沙上。", "靠近栈台的水比较深，鱼线抛远些更容易遇上大鱼。", "渔屋旁有一段背风的岸，天气变了可以在那里收好鱼具。"],
		"child": ["每次退潮我都来潮池找贝壳，但最小的那些要留给小螃蟹。", "木栈台上能看到很远的海面，我想把今天的浪花画下来。", "我把捡到的漂流木排成一条小船，差一点就能出发了。"],
		"cook": ["潮池里的贝类很鲜，清洗干净后只要一点盐就够了。", "海边捡来的东西先看看有没有小生物，完整的贝壳别敲开。"],
		"teacher": ["海岸上的沙粒比课堂里的细沙更粗，孩子们想拿它们做标本。", "栈台旁边是观察海浪的好地方，不过涨潮时要离水边远一点。"],
		"florist": ["咸咸的海风会让花瓣卷边，我把耐风的种子留在花店门口了。", "潮池旁的小花长得很慢，正适合教孩子们耐心观察。"],
		"ranger": ["沙丘上的草根抓住了沙土，踩出一条固定小路比四处穿行好。", "漂流木顺着海流搁在岸边，清理时要给潮池留出回水的空隙。"],
	},
	"countryside": {
		"ranger": ["溪水边的脚印新旧不一，雨后沿着树根找最容易看清。", "林间草丛高过靴子时，记得慢一点，别踩坏刚长出的菌子。", "溪桥下水流变急了，我已经在两岸都做了记号。"],
		"carpenter": ["靠山脚的直木适合做梁，弯枝留给工坊烧火更合适。", "溪桥的木钉开始松了，收集一点硬木我就能把它修牢。", "林道旁的石头可以垫高路面，雨天推车就不容易陷住。"],
		"child": ["树荫下有一条蚂蚁路，我想知道它们会不会一直走到山洞。", "溪边的圆石头像糖果一样，我挑了三颗放在口袋里。"],
		"teacher": ["林间小路很适合带学生观察树叶，但要记得结伴慢慢走。", "溪水涨落能说明山里的天气，我会让孩子们把变化记在本子上。"],
		"fisherman": ["这条溪流比海面平静，想练抛竿的话先从岸边浅水开始。", "桥脚旁的水流转弯处容易藏鱼，别把线抛到树枝上。"],
	},
	"cave": {
		"ranger": ["洞口的苔痕总朝着有水汽的一侧长，深处的空气会更冷。", "听见滴水声时先看看脚下，湿石头比黑暗更容易让人摔倒。"],
		"carpenter": ["支架要顺着岩层纹理顶住，不然再粗的木料也撑不久。", "梯子周围别堆矿石，留出返回入口的路最要紧。"],
		"doctor": ["矿洞里别勉强用尽体力，受伤后回诊所比硬撑下去安全。", "带一份能吃的东西下矿，药箱不该是你唯一的补给。"],
		"fisherman": ["洞穴积水的地方可能连着山里的暗河，别把鱼线系在松动的石头上。", "这里听不见海浪，倒能听出水从哪条岩缝里流过去。"],
	},
	"general_store_interior": {
		"shopkeeper": ["柜台后的种子按季节摆好，角落那本账簿记着最近的价格。", "储物架最下层放着下季种子，提前买好就不用赶最后一天。"],
		"carpenter": ["这排木架承了不少货，背后的横撑最好每隔一阵检查一次。", "柜台台面是本地硬木做的，耐磕碰，擦干净后还会有木香。"],
	},
	"clinic_interior": {"doctor": ["药柜按用途分了层，常用的恢复用品放在伸手就能拿到的位置。", "候诊椅朝着窗户摆，等人的时候看看院子也能放松一点。"]},
	"cafe_interior": {
		"cook": ["炉火小一点，汤里的香味反而能慢慢出来。", "靠窗桌子最受欢迎，雨天坐在那里能看着广场的水洼。"],
		"florist": ["咖啡馆窗边的光线正好，我常把新花束放在那里试颜色。", "吧台边的花瓶每天换水，陶乐说这样能让厨房也有春天的味道。"],
		"fisherman": ["这儿能听见外面的风声，风大时我会先来喝杯热茶再回海边。", "吧台上那张潮汐表很旧了，但每次涨落仍然记得很准。"],
	},
}

const REQUEST_POOLS := {
	"florist": [
		{"kind": "crop", "item": "parsnip", "label": "防风草", "reward": 90},
		{"kind": "fruit", "item": "apple", "label": "苹果", "reward": 160},
		{"kind": "resource", "item": "berry", "label": "野莓", "reward": 90},
		{"kind": "meal", "item": "berry_tart", "label": "野莓挞", "reward": 140},
	],
	"shopkeeper": [
		{"kind": "crop", "item": "turnip", "label": "芜菁", "reward": 76},
		{"kind": "artisan", "item": "pickles:pumpkin", "label": "南瓜腌菜", "reward": 240},
		{"kind": "animal", "item": "duck_egg", "label": "鸭蛋", "reward": 160},
		{"kind": "meal", "item": "field_salad", "label": "田园沙拉", "reward": 150},
	],
	"fisherman": [
		{"kind": "fish", "item": "sardine", "label": "沙丁鱼", "reward": 100},
		{"kind": "resource", "item": "shell", "label": "海贝", "reward": 100},
		{"kind": "fish", "item": "squid", "label": "鱿鱼", "reward": 240},
		{"kind": "meal", "item": "sea_skewer", "label": "海风烤串", "reward": 140},
	],
	"mayor": [
		{"kind": "crop", "item": "cauliflower", "label": "花椰菜", "reward": 370},
		{"kind": "resource", "item": "quartz", "label": "石英", "reward": 160},
		{"kind": "fish", "item": "red_snapper", "label": "红鲷", "reward": 220},
		{"kind": "artisan", "item": "mayonnaise", "label": "农家蛋黄酱", "reward": 400},
	],
	"carpenter": [
		{"kind": "resource", "item": "wood", "label": "木材", "reward": 60},
		{"kind": "resource", "item": "stone", "label": "石料", "reward": 50},
		{"kind": "animal", "item": "milk", "label": "牛奶", "reward": 180},
		{"kind": "fruit", "item": "orange", "label": "橙子", "reward": 160},
	],
	"doctor": [
		{"kind": "meal", "item": "field_salad", "label": "田园沙拉", "reward": 150},
		{"kind": "animal", "item": "milk", "label": "牛奶", "reward": 180},
		{"kind": "resource", "item": "mushroom", "label": "蘑菇", "reward": 100},
		{"kind": "meal", "item": "berry_tart", "label": "野莓挞", "reward": 150},
	],
	"cook": [
		{"kind": "fish", "item": "creek_fish", "label": "溪鱼", "reward": 100},
		{"kind": "meal", "item": "pumpkin_soup", "label": "南瓜蘑菇汤", "reward": 180},
		{"kind": "animal", "item": "egg", "label": "鸡蛋", "reward": 130},
		{"kind": "fish", "item": "squid", "label": "鱿鱼", "reward": 240},
	],
	"ranger": [
		{"kind": "resource", "item": "berry", "label": "野莓", "reward": 90},
		{"kind": "resource", "item": "mushroom", "label": "蘑菇", "reward": 100},
		{"kind": "resource", "item": "earth_crystal", "label": "地晶", "reward": 150},
		{"kind": "fish", "item": "catfish", "label": "鲶鱼", "reward": 190},
	],
	"teacher": [
		{"kind": "crop", "item": "melon", "label": "甜瓜", "reward": 520},
		{"kind": "fruit", "item": "apple", "label": "苹果", "reward": 160},
		{"kind": "meal", "item": "field_salad", "label": "田园沙拉", "reward": 150},
		{"kind": "fish", "item": "sardine", "label": "沙丁鱼", "reward": 100},
	],
	"child": [
		{"kind": "resource", "item": "shell", "label": "海贝", "reward": 90},
		{"kind": "animal", "item": "duck_egg", "label": "鸭蛋", "reward": 160},
		{"kind": "crop", "item": "powdermelon", "label": "冬瓜", "reward": 140},
		{"kind": "meal", "item": "berry_tart", "label": "野莓挞", "reward": 150},
	],
}

const MILESTONE_EVENTS := {
	"florist": [
		{"title": "花圃的谢意", "text": "小芙把亲手挑选的种子包交给你，希望它们在农场开花。", "reward": ["seed", "turnip", 3]},
		{"title": "四季花友", "text": "小芙把珍藏的草莓种子送给你，约好下次一起看花。", "reward": ["seed", "strawberry", 3]},
	],
	"shopkeeper": [
		{"title": "老顾客", "text": "阿谷退回一部分货款，感谢你一直照顾镇上的生意。", "reward": ["gold", "", 120]},
		{"title": "邻里价", "text": "阿谷把你记进熟客账本，从今以后种子按九折结算。", "reward": ["perk", "seed_discount", 1]},
	],
	"fisherman": [
		{"title": "潮汐礼物", "text": "老江送来几枚漂亮海贝，并讲了辨认潮水的方法。", "reward": ["resource", "shell", 3]},
		{"title": "听懂浮漂", "text": "老江教你从水纹判断鱼的动作，今后追鱼操作条会更宽。", "reward": ["perk", "fishing_window", 1]},
	],
	"mayor": [
		{"title": "农场扶持", "text": "林伯批准了一笔小额农场补助，希望你继续让山谷热闹起来。", "reward": ["gold", "", 150]},
		{"title": "花溪贡献奖", "text": "镇民一致感谢你的付出，林伯送来社区建设奖金。", "reward": ["gold", "", 400]},
	],
	"carpenter": [
		{"title": "结实木料", "text": "杉月留下一捆干燥木材，适合今后的建造和制作。", "reward": ["resource", "wood", 15]},
		{"title": "匠人的储备", "text": "杉月把挑好的石料送到农场，感谢你常来林地帮忙。", "reward": ["resource", "stone", 12]},
	],
	"doctor": [
		{"title": "恢复补给", "text": "白芷为你准备了恢复饮品，今天的疲劳一扫而空。", "reward": ["energy", "", 100]},
		{"title": "健康习惯", "text": "长期劳作让身体更强健，你的体力上限永久提高了十点。", "reward": ["perk", "energy_cap", 1]},
	],
	"cook": [
		{"title": "厨房边角料", "text": "陶乐留下一篮新鲜蘑菇，让你带回农场尝尝。", "reward": ["resource", "mushroom", 4]},
		{"title": "秋日食谱", "text": "陶乐分享了挑选南瓜的诀窍，也送来几包种子。", "reward": ["seed", "pumpkin", 3]},
	],
	"ranger": [
		{"title": "林间收获", "text": "青禾把巡林时采到的野莓分给你一份。", "reward": ["resource", "berry", 5]},
		{"title": "秘密菌圈", "text": "青禾告诉你林中菌圈的位置，并送来一篮蘑菇。", "reward": ["resource", "mushroom", 6]},
	],
	"teacher": [
		{"title": "课堂种植箱", "text": "知夏把课堂剩余的花椰菜种子送给农场继续培育。", "reward": ["seed", "cauliflower", 3]},
		{"title": "暑期观察作业", "text": "知夏想让孩子们观察甜瓜生长，托你在农场种下这些种子。", "reward": ["seed", "melon", 3]},
	],
	"child": [
		{"title": "最好看的贝壳", "text": "豆豆认真挑出三枚海贝，宣布你是最可靠的寻宝伙伴。", "reward": ["resource", "shell", 3]},
		{"title": "冬日约定", "text": "豆豆把珍藏的冬瓜种子交给你，等着看雪地里的新芽。", "reward": ["seed", "powdermelon", 3]},
	],
}

const MILESTONE_SCENES := {
	"florist": [
		{"beats": ["小芙把花店门口的木箱搬到阳光下，里面整整齐齐放着她自己留的种子。", "她说小时候总担心花溪的春天太短，直到看见你把第一块田照料得井井有条。"], "choices": [
			{"label": "收下芜菁种子，先从当季作物开始", "reply": "好呀，春天就从一小片新绿开始。", "reward": ["seed", "turnip", 3]},
			{"label": "把花种留给花店，带些野莓回家", "reply": "那我把最甜的野莓装给你，花种我会照看好。", "reward": ["resource", "berry", 3]},
		]},
		{"beats": ["雨后的花店飘着泥土香，小芙正在把最后一包草莓种子包好。", "她说真正的花友不是只在盛开时见面，也会记得一起等新芽。"], "choices": [
			{"label": "约好一起种草莓", "reply": "等第一片叶子展开，我就去农场找你。", "reward": ["seed", "strawberry", 3]},
			{"label": "请她把花种分给镇上的孩子", "reply": "这个主意真好，我再给你几包草莓种子，大家一起种。", "reward": ["seed", "strawberry", 6]},
		]},
	],
	"shopkeeper": [
		{"beats": ["阿谷翻开一本边角磨白的旧账簿，里面记着你第一次来买种子的日子。", "他说小店撑过淡季，靠的就是镇民愿意互相照应。"], "choices": [
			{"label": "收下退回的货款", "reply": "这是熟客该得的，往后缺什么就来找我。", "reward": ["gold", "", 120]},
			{"label": "换成几包防风草种子", "reply": "行，种子更实在，春天能多收一轮。", "reward": ["seed", "parsnip", 8]},
		]},
		{"beats": ["阿谷在柜台边挂起一块写着熟客价的小木牌，又马上把它擦得干干净净。", "他承认自己一直怕降价会让小店周转困难，但你让他相信镇上生意可以靠信任做长久。"], "choices": [
			{"label": "接受种子九折熟客价", "reply": "成交！这份信任我会记在账本最前面。", "reward": ["perk", "seed_discount", 1]},
			{"label": "请他把优惠折成一笔农场补贴", "reply": "也好，这笔钱能先帮你添置工具。", "reward": ["gold", "", 400]},
		]},
	],
	"fisherman": [
		{"beats": ["老江领你走到退潮后的礁石边，指给你看潮池里留下的细小贝壳。", "他说海边的收获不只看运气，也要学会等海水把线索带回来。"], "choices": [
			{"label": "收下他挑出的海贝", "reply": "拿回去吧，每一枚都是潮水留下的问候。", "reward": ["resource", "shell", 3]},
			{"label": "请他教你认沙丁鱼的鱼汛", "reply": "把这几条鲜鱼带回去，今晚正好做汤。", "reward": ["resource", "shell", 5]},
		]},
		{"beats": ["老江把浮漂放进海湾，让你先观察水面，而不是急着收线。", "他说耐心也能练成手艺，愿意把自己多年的经验交给你。"], "choices": [
			{"label": "学习追鱼时机", "reply": "以后手稳些，鱼就不会轻易从你的操作条里溜走。", "reward": ["perk", "fishing_window", 1]},
			{"label": "收下他的潮汐记录本", "reply": "这上面记着不少好潮日子，贝壳也送你几枚。", "reward": ["resource", "shell", 8]},
		]},
	],
	"mayor": [
		{"beats": ["林伯带你看镇公所抽屉里积了多年的农场申请表。", "他说这笔补助不只是账面数字，也是镇上重新热闹起来的证明。"], "choices": [
			{"label": "收下农场扶持金", "reply": "拿去添置真正需要的东西吧，农场也是花溪的一部分。", "reward": ["gold", "", 150]},
			{"label": "把补助换成社区菜园种子", "reply": "邻里一起种更有意思，南瓜种子我替你准备。", "reward": ["seed", "pumpkin", 4]},
		]},
		{"beats": ["广场的长桌刚擦拭完，林伯把一张写满居民签名的感谢卡递给你。", "他说修复会堂和照顾农场都让大家重新愿意聚在一起。"], "choices": [
			{"label": "收下花溪贡献奖金", "reply": "这是大家的心意，也盼你继续和我们一起建设这里。", "reward": ["gold", "", 400]},
			{"label": "把奖金的一部分换成修缮木料", "reply": "这批木料留给你建农场设施，也算镇上回赠的帮忙。", "reward": ["resource", "wood", 20]},
		]},
	],
	"carpenter": [
		{"beats": ["杉月带你走进工坊后院，几根木料被她按纹理和用途仔细分开。", "她说好材料要交给愿意认真使用的人，而不是只看谁砍得多。"], "choices": [
			{"label": "收下干燥木料", "reply": "这些已经风干好了，拿去做结实的东西。", "reward": ["resource", "wood", 15]},
			{"label": "改拿一批砌墙石料", "reply": "可以，石头我也挑过，砌围栏正合适。", "reward": ["resource", "stone", 12]},
		]},
		{"beats": ["杉月把一把刻着树纹的小尺放在工作台上，说这是师傅留给她的。", "她请你挑一份储备材料，作为以后一起修桥和盖屋的约定。"], "choices": [
			{"label": "收下她挑好的石料", "reply": "等你准备好，我会陪你把第一面墙砌起来。", "reward": ["resource", "stone", 12]},
			{"label": "请她留下木料做梁柱", "reply": "好木料用在梁上最稳，这捆给你的农场。", "reward": ["resource", "wood", 20]},
		]},
	],
	"doctor": [
		{"beats": ["白芷在诊所后院给几株草药松土，桌上放着她刚调好的恢复饮品。", "她说照顾别人之前，也要先记得给自己的身体留一点余裕。"], "choices": [
			{"label": "喝下恢复饮品，歇一会儿", "reply": "慢慢喝，不用急着马上回去干活。", "reward": ["energy", "", 100]},
			{"label": "把饮品留给诊所病人", "reply": "那我给你准备些野莓，路上饿了可以吃。", "reward": ["resource", "berry", 5]},
		]},
		{"beats": ["白芷翻出你几个月来的劳作记录，提醒你体力消耗已经比刚来时更稳。", "她希望你继续量力而行，也决定把这份长期进步记录为健康奖励。"], "choices": [
			{"label": "接受体力上限提升", "reply": "身体照顾得好，才能陪农场走得更远。", "reward": ["perk", "energy_cap", 1]},
			{"label": "先把恢复饮品带回农场", "reply": "好，遇到特别忙的日子就用它缓一缓。", "reward": ["energy", "", 100]},
		]},
	],
	"cook": [
		{"beats": ["陶乐让你尝了一小口新汤，厨房里还留着当天採回来的蘑菇。", "他笑说一道好菜不需要昂贵食材，知道食物从哪里来更重要。"], "choices": [
			{"label": "带一篮新鲜蘑菇回家", "reply": "给你挑了最嫩的，回去配点蔬菜就很好吃。", "reward": ["resource", "mushroom", 4]},
			{"label": "把蘑菇留给咖啡馆，换辣椒种子", "reply": "行，厨房的辣椒正好适合留种，拿去试种几株。", "reward": ["seed", "pepper", 3]},
		]},
		{"beats": ["陶乐在食谱本上画了几笔南瓜的成熟纹路，提醒你别只看果实大小。", "他说最好的料理始于耐心，也把秋天的新配方交给你试做。"], "choices": [
			{"label": "带走南瓜种子，试着种一季", "reply": "等收成了再来，我想听听农场南瓜的味道。", "reward": ["seed", "pumpkin", 3]},
			{"label": "把食谱讲给镇上的孩子", "reply": "好主意，我再给你几包咖啡馆留存的辣椒种子。", "reward": ["seed", "pepper", 6]},
		]},
	],
	"ranger": [
		{"beats": ["青禾在郊区的小径旁发现一片熟透的野莓，已经被鸟儿啄掉几颗。", "她说林地不是谁的仓库，采集时记得给下一季留种子。"], "choices": [
			{"label": "收下她分来的野莓", "reply": "挑红透的拿走吧，剩下的留给鸟和新枝。", "reward": ["resource", "berry", 5]},
			{"label": "把野莓留在林地，带些木料回去", "reply": "谢谢你愿意留一点给森林，巡林木料你拿去用。", "reward": ["resource", "wood", 10]},
		]},
		{"beats": ["青禾终于带你找到那片藏在树根间的菌圈，地面上还留着新长出的菌丝。", "她提醒你只采外围成熟的部分，让这片林子明年还能回来。"], "choices": [
			{"label": "带走成熟蘑菇", "reply": "我帮你装好了，菌圈中央要留给它继续生长。", "reward": ["resource", "mushroom", 6]},
			{"label": "让菌圈继续生长，带走巡林贝饰", "reply": "这个小护身饰送你，提醒自己常回来看看森林。", "reward": ["resource", "shell", 4]},
		]},
	],
	"teacher": [
		{"beats": ["知夏把孩子们的种植箱搬到窗边，里面几株苗长得比预想中慢。", "她说照料和观察一样重要，不必为了赶进度把每颗种子都拔出来看。"], "choices": [
			{"label": "把花椰菜种子带回农场继续观察", "reply": "记下每天的变化吧，孩子们也会期待你的记录。", "reward": ["seed", "cauliflower", 3]},
			{"label": "把课堂余下的芜菁种子分给邻居", "reply": "真贴心，我给你的农场再留一小包。", "reward": ["seed", "turnip", 6]},
		]},
		{"beats": ["知夏把暑期观察作业的纸张铺满桌面，孩子们最想知道果实怎么从小花长出来。", "她请你选择一种作物，让农场成为大家共同记录的课堂。"], "choices": [
			{"label": "种下甜瓜，记录整个生长期", "reply": "太好了，等成熟时我带孩子们来听你的经验。", "reward": ["seed", "melon", 3]},
			{"label": "从更容易观察的花椰菜开始", "reply": "循序渐进也很好，我把课堂留种交给你。", "reward": ["seed", "cauliflower", 3]},
		]},
	],
	"child": [
		{"beats": ["豆豆把找到的贝壳摆成一排，每一枚都画了不同的笑脸。", "他认真地说寻宝最重要的不是找到多少，而是愿意一起蹲下来找。"], "choices": [
			{"label": "收下最好看的三枚贝壳", "reply": "这三枚给你！下次我们再去潮池找新的。", "reward": ["resource", "shell", 3]},
			{"label": "把贝壳留给海边的小生物", "reply": "那我送你几颗野莓，路上可以边走边吃。", "reward": ["resource", "berry", 3]},
		]},
		{"beats": ["豆豆把一包冬瓜种子藏在外套口袋里，直到确认你还记得冬日约定才拿出来。", "他说等雪落下来，也想在农场的小屋里画下新芽。"], "choices": [
			{"label": "一起种冬瓜，等雪天观察", "reply": "我会把画纸准备好，等看到叶子就画下来！", "reward": ["seed", "powdermelon", 3]},
			{"label": "先把种子送给老师做课堂实验", "reply": "这样大家都能看到，我把捡到的贝壳送给你。", "reward": ["resource", "shell", 5]},
		]},
	],
}

var bonds: Dictionary = {}
var festival_visits: Dictionary = {}
var festival_hunts: Dictionary = {}
var claimed: Dictionary = {}
var request_days: Dictionary = {}
var milestones: Dictionary = {}

func activity(actor: String, day: int, minutes: int) -> Dictionary:
	if not Calendar.festival(day).is_empty(): return {"map": "town_square", "label": "参加节日"}
	if minutes >= 1140 or Calendar.weather(day) == "雨": return {"map": "general_store_interior" if actor in ["shopkeeper", "carpenter"] else "cafe_interior", "label": "室内休息"}
	if actor == "shopkeeper" and minutes >= 600 and minutes < 960: return {"map": "general_store_interior", "label": "照看种子铺"}
	if actor == "doctor" and minutes >= 540 and minutes < 1020: return {"map": "clinic_interior", "label": "在诊所值班"}
	if actor == "cook" and minutes >= 600 and minutes < 1140: return {"map": "cafe_interior", "label": "准备餐点"}
	if actor == "carpenter" and minutes >= 480 and minutes < 960: return {"map": "countryside", "label": "在郊区检查木料"}
	if actor == "ranger" and minutes >= 480 and minutes < 1080: return {"map": "countryside", "label": "巡视郊区林地"}
	if actor == "florist" and minutes >= 720 and minutes < 840: return {"map": "cafe_interior", "label": "午间喝茶"}
	if actor == "fisherman" and minutes >= 600 and minutes < 1020: return {"map": "beach", "label": "在沙滩照看潮水"}
	if actor == "child" and Calendar.date(day).weekday in [5, 6] and minutes >= 720 and minutes < 1020: return {"map": "beach", "label": "在沙滩玩耍"}
	return {"map": "town_square", "label": "广场散步"}

func request(actor: String, day: int) -> Dictionary:
	if not PEOPLE.has(actor): return {}
	var pool: Array = REQUEST_POOLS.get(actor, [])
	if pool.is_empty(): return {}
	var date := Calendar.date(day)
	var actor_index := PEOPLE.keys().find(actor)
	var week := floori(float(int(date.day) - 1) / 7.0)
	var slot := posmod(week + int(date.season) + int(date.year) - 1 + actor_index, pool.size())
	var result: Dictionary = pool[slot].duplicate(true)
	result["done"] = int(request_days.get(actor, 0)) == day
	return result


func can_deliver_request(actor: String, day: int, gift_kind: String, item_id: String) -> bool:
	var wanted := request(actor, day)
	return not wanted.is_empty() and not bool(wanted.get("done", false)) and str(wanted.kind) == gift_kind and str(wanted.item) == item_id


func complete_request(actor: String, farm) -> Dictionary:
	var wanted := request(actor, farm.day)
	if wanted.is_empty(): return {"ok": false, "message": "这里没有居民委托。"}
	if bool(wanted.done): return {"ok": false, "message": "今天的委托已经完成，明天再来看看吧。"}
	var reward := int(wanted.reward)
	request_days[actor] = farm.day
	farm.gold += reward
	farm.gold_changed.emit(farm.gold, reward)
	var relation := bond(actor)
	relation.points = mini(1000, int(relation.points) + 40)
	return {"ok": true, "item": str(wanted.item), "kind": str(wanted.kind), "label": str(wanted.label), "reward": reward, "message": "谢谢你带来的%s！委托完成：%d 金，友好度 +40。" % [wanted.label, reward]}

func deliver(actor: String, farm) -> String:
	var wanted := request(actor, farm.day)
	if wanted.is_empty(): return "这里没有这位居民。"
	if wanted.done: return "今天的委托已经完成，明天再来看看吧。"
	if str(wanted.kind) != "crop": return "这项委托需要从行囊中交付%s。" % wanted.label
	if farm.get_harvest_count(wanted.item) < 1: return "背包中还没有委托需要的%s。" % wanted.label
	farm.harvest_inventory[wanted.item] -= 1
	farm.inventory_changed.emit("harvest", wanted.item, farm.get_harvest_count(wanted.item))
	return str(complete_request(actor, farm).message)

func bond(actor: String) -> Dictionary:
	if not bonds.has(actor):
		bonds[actor] = {"points": 0, "talk_day": 0, "gift_day": 0}
	return bonds[actor]


func available_milestone(actor: String) -> Dictionary:
	if not MILESTONE_EVENTS.has(actor): return {}
	var points := int(bond(actor).points)
	var claimed_level := int(milestones.get(actor, 0))
	var next_level := claimed_level + 1
	var threshold := 200 if next_level == 1 else 500 if next_level == 2 else 1001
	if points < threshold: return {}
	var event: Dictionary = MILESTONE_EVENTS[actor][next_level - 1].duplicate(true)
	var scene: Dictionary = MILESTONE_SCENES[actor][next_level - 1].duplicate(true)
	event.merge(scene, true)
	event["actor"] = actor
	event["level"] = next_level
	event["threshold"] = threshold
	return event


func claim_milestone(actor: String, level: int, choice_index: int) -> Dictionary:
	var event := available_milestone(actor)
	if event.is_empty() or int(event.level) != level: return {}
	var choices: Array = event.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size(): return {}
	var choice: Dictionary = choices[choice_index]
	event["reward"] = choice.reward.duplicate(true)
	event["choice_reply"] = str(choice.reply)
	event["choice_label"] = str(choice.label)
	milestones[actor] = level
	return event


func has_milestone(actor: String, level: int) -> bool:
	return int(milestones.get(actor, 0)) >= level

func talk(actor: String, day: int, minutes := 360, location := "") -> String:
	if not PEOPLE.has(actor): return "你好。"
	var person: Dictionary = PEOPLE[actor]
	var relation := bond(actor)
	var fresh := int(relation.talk_day) != day
	if fresh:
		relation.talk_day = day
		relation.points = mini(1000, int(relation.points) + 20)
	var event := Calendar.festival(day)
	var is_birthday := (day - 1) % 112 + 1 == int(person.birthday)
	var line: String = person.lines[Calendar.date(day).season]
	if not event.is_empty():
		var key := str(day)
		if not festival_visits.has(key): festival_visits[key] = []
		if not actor in festival_visits[key]: festival_visits[key].append(actor)
		line = "今天是%s！%s。" % [event.name, event.activity]
	elif is_birthday:
		line = "今天是我的生日，能见到你真开心。"
	elif int(relation.points) >= 200:
		line += " 有你这位朋友，花溪镇更热闹了。"
	else:
		var moments := ["今天想在镇上多走走，看看大家的近况。", "昨晚风吹过窗边，早上醒来特别精神。", "有空带着你家的小狗来玩吧。", "忙完农活也别忘了坐下来歇一歇。"]
		line += " " + str(moments[(day + PEOPLE.keys().find(actor)) % moments.size()])
	if event.is_empty() and not is_birthday:
		var scene_line := scene_dialogue(actor, location, day)
		if not scene_line.is_empty(): line += "\n" + scene_line
	line += "\n" + ("下雨了，进屋避避雨吧。" if Calendar.weather(day) == "雨" else "早上好，新的一天开始啦。" if minutes < 600 else "我正%s。" % activity(actor, day, minutes).label)
	return "%s · %s\n\n%s\n\n友好度 %d / 1000%s" % [person.name, person.job, line, relation.points, "（今日聊天 +20）" if fresh else "（今天已经聊过了）"]


func scene_dialogue(actor: String, location: String, day: int) -> String:
	var by_resident: Dictionary = SCENE_BANTER.get(location, {})
	var lines: Array = by_resident.get(actor, [])
	if lines.is_empty(): return ""
	var actor_index := PEOPLE.keys().find(actor)
	return str(lines[posmod(day + actor_index, lines.size())])

func gift_value(actor: String, item: String, day: int) -> Dictionary:
	if not PEOPLE.has(actor): return {"ok": false, "message": "这里没有这位居民。"}
	var preference: Dictionary = GIFT_PREFERENCES.get(actor, {})
	var tier := "neutral"
	if item in preference.get("hated", []): tier = "hated"
	elif item in preference.get("disliked", []): tier = "disliked"
	elif item in preference.get("loved", []) or str(PEOPLE[actor].likes) == item: tier = "loved"
	elif item in preference.get("liked", []): tier = "liked"
	var points := int({"loved": 80, "liked": 45, "neutral": 20, "disliked": -20, "hated": -40}[tier])
	var birthday := posmod(day - 1, 112) + 1 == int(PEOPLE[actor].birthday)
	if birthday: points *= 8
	var response := str({"loved": "你怎么知道我一直想要这个！", "liked": "这个正合我意，谢谢你。", "neutral": "谢谢你的心意，我会收下。", "disliked": "我可能用不上，不过还是谢谢你。", "hated": "我不喜欢这个……下次不用特意带来。"}[tier])
	return {"ok": true, "tier": tier, "points": points, "response": response, "birthday": birthday}


func record_gift(actor: String, item: String, day: int) -> Dictionary:
	if not PEOPLE.has(actor): return {"ok": false, "message": "这里没有这位居民。"}
	var relation := bond(actor)
	if int(relation.gift_day) == day: return {"ok": false, "message": "今天已经送过礼物，明天再来吧。"}
	var result := gift_value(actor, item, day)
	if not bool(result.get("ok", false)): return result
	var previous := int(relation.points)
	relation.gift_day = day
	relation.points = clampi(previous + int(result.points), 0, 1000)
	result.points = int(relation.points) - previous
	result["total"] = int(relation.points)
	result["name"] = str(PEOPLE[actor].name)
	return result


func gift(actor: String, item: String, farm) -> String:
	if not PEOPLE.has(actor): return "这里没有可以送礼的居民。"
	if farm.get_harvest_count(item) < 1: return "背包没有这份作物。请先收获，或换一份礼物。"
	var result := record_gift(actor, item, farm.day)
	if not bool(result.get("ok", false)): return str(result.get("message", "现在不能送礼。"))
	farm.harvest_inventory[item] -= 1
	farm.inventory_changed.emit("harvest", item, farm.get_harvest_count(item))
	return "%s：%s 友好度 +%d。" % [result.name, result.response, int(result.points)]

func join_festival(farm) -> String:
	var event := Calendar.festival(farm.day)
	if event.is_empty(): return "今天没有节日，看看日历准备下一场聚会吧。"
	var key := str(farm.day)
	if claimed.has(key): return "今天已经完成活动并领取奖励，享受节日吧！"
	var required := 0
	if event.id == "summer": required = 1
	if event.id == "harvest": required = 3
	if event.id == "blossom" and not festival_hunt_complete(farm.day):
		return "先参加春日寻花挑战，找到六枚印花后再来领取奖励。"
	if event.id == "winter" and festival_visits.get(key, []).size() < 3:
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


func record_spring_festival_hunt(day: int, found_count: int, elapsed_seconds: float) -> bool:
	if Calendar.festival(day).get("id", "") != "blossom" or found_count < 6: return false
	var key := str(day)
	var previous: Dictionary = festival_hunts.get(key, {})
	var elapsed := maxi(0, roundi(elapsed_seconds))
	if previous.is_empty() or elapsed < int(previous.get("seconds", 2147483647)):
		festival_hunts[key] = {"found": found_count, "seconds": elapsed}
	return true


func festival_hunt_complete(day: int) -> bool:
	var result = festival_hunts.get(str(day), {})
	return result is Dictionary and int(result.get("found", 0)) >= 6

func snapshot() -> Dictionary:
	return {"bonds": bonds.duplicate(true), "visits": festival_visits.duplicate(true), "hunts": festival_hunts.duplicate(true), "claimed": claimed.duplicate(true), "request_days": request_days.duplicate(), "milestones": milestones.duplicate()}

func restore(data: Dictionary) -> void:
	bonds = data.get("bonds", {}).duplicate(true)
	for relation in bonds.values():
		relation.points = clampi(int(relation.points), 0, 1000)
		relation.talk_day = int(relation.talk_day)
		relation.gift_day = int(relation.gift_day)
	festival_visits = data.get("visits", {}).duplicate(true)
	festival_hunts = data.get("hunts", {}).duplicate(true)
	for day in festival_hunts.keys():
		var hunt = festival_hunts[day]
		if not hunt is Dictionary:
			festival_hunts.erase(day)
			continue
		hunt["found"] = int(hunt.get("found", 0))
		hunt["seconds"] = int(hunt.get("seconds", 0))
	claimed = data.get("claimed", {}).duplicate(true)
	request_days = data.get("request_days", {}).duplicate()
	milestones.clear()
	for actor in data.get("milestones", {}):
		if PEOPLE.has(actor): milestones[actor] = clampi(int(data.milestones[actor]), 0, 2)
