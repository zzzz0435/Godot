class_name CardSlotUI
extends PanelContainer

signal slot_clicked(slot_index: int)

var slot_index: int = 0
var current_card: CardData = null

@onready var label: Label = $Label

const TYPE_COLORS: Dictionary = {
	CardData.CardType.ATTACK:   Color(0.85, 0.25, 0.25),
	CardData.CardType.GUARD:    Color(0.25, 0.45, 0.85),
	CardData.CardType.CLOSE_UP: Color(0.90, 0.75, 0.10),
}

func _ready() -> void:
	_refresh()

func place_card(data: CardData) -> void:
	current_card = data
	_refresh()

func remove_card() -> CardData:
	var removed := current_card
	current_card = null
	_refresh()
	return removed

func is_empty() -> bool:
	return current_card == null

func _refresh() -> void:
	var style := StyleBoxFlat.new()
	style.set_border_width_all(4)
	style.border_color = Color.BLACK
	if current_card == null:
		label.text = "—"
		style.bg_color = Color.WHITE
	else:
		label.text = current_card.card_name
		style.bg_color = TYPE_COLORS[current_card.card_type]
	style.set_corner_radius_all(2)
	add_theme_stylebox_override("panel", style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		slot_clicked.emit(slot_index)
