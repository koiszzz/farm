extends Sprite2D

## A raised object renders at its ground depth; transparent art never occludes.
var source_image: Image

func covers(point: Vector2) -> bool:
	var local := to_local(point)
	if not Rect2(Vector2.ZERO, region_rect.size).has_point(local): return false
	var pixel := Vector2i(region_rect.position + local)
	return source_image.get_pixelv(pixel).a > 0.35
