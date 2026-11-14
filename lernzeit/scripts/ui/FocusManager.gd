class_name FocusManager
extends RefCounted
## Explicit D-pad navigation helpers. Edges point to the control itself, so
## focus can never "fall out" of a screen or jump to a hidden element.

static func set_neighbors(c: Control, left: Control = null, right: Control = null,
		up: Control = null, down: Control = null) -> void:
	c.focus_neighbor_left = c.get_path_to(left if left else c)
	c.focus_neighbor_right = c.get_path_to(right if right else c)
	c.focus_neighbor_top = c.get_path_to(up if up else c)
	c.focus_neighbor_bottom = c.get_path_to(down if down else c)
	c.focus_next = c.get_path_to(right if right else (down if down else c))
	c.focus_previous = c.get_path_to(left if left else (up if up else c))


static func set_one(c: Control, side: Side, target: Control) -> void:
	var p := c.get_path_to(target if target else c)
	match side:
		SIDE_LEFT: c.focus_neighbor_left = p
		SIDE_RIGHT: c.focus_neighbor_right = p
		SIDE_TOP: c.focus_neighbor_top = p
		SIDE_BOTTOM: c.focus_neighbor_bottom = p


## Horizontal chain: left/right between items; up/down left untouched.
static func link_row(items: Array, wrap: bool = false) -> void:
	var n := items.size()
	for i in n:
		var c: Control = items[i]
		var l: Control = items[i - 1] if i > 0 else (items[n - 1] if wrap else c)
		var r: Control = items[i + 1] if i < n - 1 else (items[0] if wrap else c)
		set_one(c, SIDE_LEFT, l)
		set_one(c, SIDE_RIGHT, r)


## Vertical chain: up/down between items; left/right left untouched.
static func link_column(items: Array, wrap: bool = false) -> void:
	var n := items.size()
	for i in n:
		var c: Control = items[i]
		var u: Control = items[i - 1] if i > 0 else (items[n - 1] if wrap else c)
		var d: Control = items[i + 1] if i < n - 1 else (items[0] if wrap else c)
		set_one(c, SIDE_TOP, u)
		set_one(c, SIDE_BOTTOM, d)


## Sets one side of several controls to the same target.
static func point_all(items: Array, side: Side, target: Control) -> void:
	for c in items:
		set_one(c, side, target)


static func first_focusable(nodes: Array) -> Control:
	for n in nodes:
		if n is Control and n.focus_mode != Control.FOCUS_NONE and n.is_visible_in_tree():
			return n
	return null
