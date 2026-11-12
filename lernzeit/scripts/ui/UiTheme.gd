class_name UiTheme
extends RefCounted
## Builds the app theme in code. All font sizes are multiplied by the
## "Schriftgröße" factor (Normal 1.0 / Groß 1.18). Base canvas: 1920×1080.

const NAVY := Color("16257a")
const NAVY_SOFT := Color("33418f")
const WHITE := Color.WHITE
const FOCUS := Color("62e6ff")
const SHADOW := Color(0.04, 0.10, 0.35, 0.55)

const FONT_BOLD := "res://assets/fonts/Nunito_700Bold.ttf"
const FONT_XBOLD := "res://assets/fonts/Nunito_800ExtraBold.ttf"
const FONT_SEMI := "res://assets/fonts/Nunito_600SemiBold.ttf"

## variation: [font, size, color, outline_size, shadow]
const LABELS := {
	"TitleLabel": [FONT_XBOLD, 62, WHITE, 10, true],
	"PromptLabel": [FONT_XBOLD, 50, WHITE, 10, true],
	"CardTitle": [FONT_XBOLD, 60, WHITE, 0, true],
	"CardSubtitle": [FONT_BOLD, 32, Color(1, 1, 1, 0.95), 0, true],
	"HeadingLabel": [FONT_XBOLD, 40, NAVY, 0, false],
	"RowTitle": [FONT_XBOLD, 34, NAVY, 0, false],
	"BodyLabel": [FONT_BOLD, 30, NAVY, 0, false],
	"CaptionLabel": [FONT_SEMI, 26, NAVY_SOFT, 0, false],
	"OnDarkBody": [FONT_BOLD, 30, WHITE, 6, true],
	"OnDarkCaption": [FONT_SEMI, 26, WHITE, 5, true],
	"StatValue": [FONT_XBOLD, 64, NAVY, 0, false],
	"PinDigit": [FONT_XBOLD, 44, NAVY, 0, false],
	"ToastLabel": [FONT_BOLD, 30, WHITE, 0, false],
}

static var _fonts := {}


static func font(path: String) -> Font:
	if not _fonts.has(path):
		var f: FontFile = load(path)
		f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		f.hinting = TextServer.HINTING_LIGHT
		f.generate_mipmaps = true
		_fonts[path] = f
	return _fonts[path]


static func build(scale: float) -> Theme:
	var th := Theme.new()
	th.default_font = font(FONT_BOLD)
	th.default_font_size = int(30 * scale)
	for name in LABELS:
		var spec: Array = LABELS[name]
		th.set_type_variation(name, "Label")
		th.set_font("font", name, font(spec[0]))
		th.set_font_size("font_size", name, int(round(spec[1] * scale)))
		th.set_color("font_color", name, spec[2])
		if spec[3] > 0:
			th.set_constant("outline_size", name, spec[3])
			th.set_color("font_outline_color", name, Color(0.07, 0.16, 0.5, 0.55))
		if spec[4]:
			th.set_color("font_shadow_color", name, SHADOW)
			th.set_constant("shadow_offset_x", name, 0)
			th.set_constant("shadow_offset_y", name, 3)
			th.set_constant("shadow_outline_size", name, 4)
	# Buttons (styleboxes are set per PillButton variant)
	th.set_type_variation("PillButton", "Button")
	th.set_font("font", "PillButton", font(FONT_XBOLD))
	th.set_font_size("font_size", "PillButton", int(round(32 * scale)))
	th.set_type_variation("SmallPill", "Button")
	th.set_font("font", "SmallPill", font(FONT_XBOLD))
	th.set_font_size("font_size", "SmallPill", int(round(27 * scale)))
	th.set_font_size("font_size", "LineEdit", int(round(34 * scale)))
	th.set_color("font_color", "LineEdit", NAVY)
	th.set_color("font_placeholder_color", "LineEdit", Color(NAVY, 0.45))
	th.set_color("caret_color", "LineEdit", NAVY)
	var le := StyleBoxFlat.new()
	le.bg_color = Color(1, 1, 1, 0.92)
	le.set_corner_radius_all(22)
	le.set_border_width_all(3)
	le.border_color = Color("8fb4ff")
	le.content_margin_left = 24
	le.content_margin_right = 24
	le.content_margin_top = 12
	le.content_margin_bottom = 12
	th.set_stylebox("normal", "LineEdit", le)
	var lef := le.duplicate()
	lef.border_color = FOCUS
	lef.set_border_width_all(6)
	th.set_stylebox("focus", "LineEdit", lef)
	# Scroll containers: slim, unobtrusive bar
	var bar := StyleBoxFlat.new()
	bar.bg_color = Color(1, 1, 1, 0.18)
	bar.set_corner_radius_all(6)
	bar.content_margin_left = 6
	bar.content_margin_right = 6
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(1, 1, 1, 0.6)
	grab.set_corner_radius_all(6)
	th.set_stylebox("scroll", "VScrollBar", bar)
	th.set_stylebox("grabber", "VScrollBar", grab)
	th.set_stylebox("grabber_highlight", "VScrollBar", grab)
	th.set_stylebox("grabber_pressed", "VScrollBar", grab)
	return th


## Focus ring used by every focusable element (blue glow frame).
static func focus_ring(radius: int, width: int = 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.draw_center = false
	sb.set_border_width_all(width)
	sb.border_color = FOCUS
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0.38, 0.9, 1.0, 0.65)
	sb.shadow_size = 18
	sb.anti_aliasing = true
	return sb
