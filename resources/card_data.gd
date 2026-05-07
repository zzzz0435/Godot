class_name CardData
extends Resource

enum CardType { ATTACK, GUARD, CLOSE_UP }

@export var card_name: String = ""
@export var card_type: CardType = CardType.ATTACK
@export var description: String = ""
