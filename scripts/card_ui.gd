class_name CardUI
extends PanelContainer

signal card_clicked(card_data: CardData)

var card_data: CardData

@onready var label: Label = $Label

const TYPE_COLORS: Dictionary = {
	CardData.CardType.ATTACK:   Color(0.85, 0.25, 0.25),
	CardData.CardType.GUARD:    Color(0.25, 0.45, 0.85),
	CardData.CardType.CLOSE_UP: Color(0.90, 0.75, 0.10),
}

func setup(data: CardData) -> void:
	card_data = data
	label.text = data.card_name
	var style := StyleBoxFlat.new()
	style.bg_color = TYPE_COLORS[data.card_type]
	style.set_border_width_all(2)
	style.border_color = Color.BLACK
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(card_data)
