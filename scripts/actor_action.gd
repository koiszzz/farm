class_name ActorAction
extends RefCounted

## One transaction per animation. The contact callback commits gameplay once;
## cancelling before contact has no inventory or energy side effects.
const DURATIONS := {"sword": 0.45, "pickaxe": 0.65, "hoe": 0.70, "seed": 0.55, "water": 0.95, "harvest": 0.70, "scythe": 0.75, "gift": 0.90, "fish": 1.20, "pet": 1.0}
var kind := ""
var elapsed := 0.0
var duration := 0.0
var committed := false
var _contact: Callable
var _finish: Callable

func start(next_kind: String, contact: Callable, finish := Callable()) -> bool:
	if not kind.is_empty(): return false
	kind = next_kind
	duration = float(DURATIONS.get(kind, 0.7))
	elapsed = 0.0
	committed = false
	_contact = contact
	_finish = finish
	return true

func advance(delta: float) -> void:
	if kind.is_empty(): return
	elapsed += maxf(delta, 0.0)
	if not committed and progress() >= 0.48:
		committed = true
		if _contact.is_valid(): _contact.call()
	if elapsed >= duration:
		var callback := _finish
		cancel()
		if callback.is_valid(): callback.call()

func progress() -> float:
	return clampf(elapsed / maxf(duration, 0.01), 0.0, 1.0)

func cancel() -> void:
	kind = ""
	_contact = Callable()
	_finish = Callable()
