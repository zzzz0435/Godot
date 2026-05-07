extends VBoxContainer

enum State { DRAW, SELECT, EXECUTE, ENEMY_TURN, RESULT }

const ATTACK_DAMAGE  := 3
const GUARD_SHIELD   := 2
const CLOSE_UP_MULT  := 2
const HAND_SIZE      := 5
const SLOT_COUNT     := 3

var player: PlayerState
var enemy: EnemyState
var current_state: State = State.DRAW

var card_slot_scene: PackedScene = preload("res://scenes/card_slot.tscn")
var card_scene:      PackedScene = preload("res://scenes/card.tscn")

var card_pool: Array[CardData] = []
var slot_nodes: Array[CardSlotUI] = []

@onready var enemy_label:    Label        = $EnemyArea/EnemyLabel
@onready var enemy_hp_bar:   ProgressBar  = $EnemyArea/EnemyHPBar
@onready var storyboard_area: HBoxContainer = $StoryboardArea
@onready var hand_area:      HBoxContainer = $HandArea
@onready var player_hp_bar:  ProgressBar  = $PlayerArea/PlayerHPBar
@onready var player_hp_label: Label       = $PlayerArea/PlayerHPLabel
@onready var shield_label:   Label        = $PlayerArea/ShieldLabel
@onready var execute_button: Button       = $BottomArea/ExecuteButton
@onready var battle_log:     RichTextLabel = $BattleLog
@onready var result_label:   Label        = $ResultLabel

func _ready() -> void:
	player = PlayerState.new()
	enemy  = EnemyState.new()

	var attack_card:   CardData = load("res://resources/cards/attack.tres")
	var guard_card:    CardData = load("res://resources/cards/guard.tres")
	var close_up_card: CardData = load("res://resources/cards/close_up.tres")

	for _i in 4: card_pool.append(attack_card)
	for _i in 3: card_pool.append(guard_card)
	for _i in 3: card_pool.append(close_up_card)

	for i in SLOT_COUNT:
		var slot := card_slot_scene.instantiate() as CardSlotUI
		slot.slot_index = i
		slot.slot_clicked.connect(_on_slot_clicked)
		storyboard_area.add_child(slot)
		slot_nodes.append(slot)

	execute_button.pressed.connect(_on_execute_pressed)
	result_label.visible = false

	_update_ui()
	_change_state(State.DRAW)

# ── State machine ──────────────────────────────────────────────

func _change_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.DRAW:       _do_draw()
		State.SELECT:     _do_select()
		State.EXECUTE:    _do_execute()
		State.ENEMY_TURN: _do_enemy_turn()

func _do_draw() -> void:
	for child in hand_area.get_children():
		child.queue_free()

	var pool_copy := card_pool.duplicate()
	pool_copy.shuffle()
	for i in HAND_SIZE:
		var card_node := card_scene.instantiate() as CardUI
		hand_area.add_child(card_node)
		card_node.setup(pool_copy[i])
		card_node.card_clicked.connect(_on_card_clicked)

	_log("── 新的一回合，抽了 %d 張牌 ──" % HAND_SIZE)
	_change_state(State.SELECT)

func _do_select() -> void:
	_refresh_execute_button()

func _do_execute() -> void:
	execute_button.disabled = true
	var multiplier := 1

	for slot in slot_nodes:
		if slot.is_empty():
			if multiplier == CLOSE_UP_MULT:
				_log("CloseUp 效果：下一格為空，倍率浪費。")
				multiplier = 1
			continue

		match slot.current_card.card_type:
			CardData.CardType.ATTACK:
				var dmg := ATTACK_DAMAGE * multiplier
				enemy.current_hp -= dmg
				_log("⚔ Attack ×%d → 敵人受到 %d 傷害（HP: %d）" % [multiplier, dmg, enemy.current_hp])
				multiplier = 1

			CardData.CardType.GUARD:
				var gained := GUARD_SHIELD * multiplier
				player.shield += gained
				_log("🛡 Guard ×%d → 獲得 %d 護盾（Shield: %d）" % [multiplier, gained, player.shield])
				multiplier = 1

			CardData.CardType.CLOSE_UP:
				multiplier = CLOSE_UP_MULT
				_log("🎬 CloseUp！下一張卡效果 × %d" % CLOSE_UP_MULT)

	for slot in slot_nodes:
		slot.remove_card()

	_update_ui()

	if _check_result():
		return
	_change_state(State.ENEMY_TURN)

func _do_enemy_turn() -> void:
	var total   := enemy.attack_damage
	var absorbed := mini(player.shield, total)
	player.shield     -= absorbed
	player.current_hp -= (total - absorbed)

	_log("👹 敵人攻擊 %d（護盾吸收 %d，HP 損失 %d）" % [total, absorbed, total - absorbed])
	_update_ui()

	if _check_result():
		return
	_change_state(State.DRAW)

# ── Input handlers ─────────────────────────────────────────────

func _on_card_clicked(card_data: CardData) -> void:
	if current_state != State.SELECT:
		return
	for slot in slot_nodes:
		if slot.is_empty():
			# 找到發出訊號的 CardUI 節點並移除
			for child in hand_area.get_children():
				if child is CardUI and child.card_data == card_data:
					slot.place_card(card_data)
					child.queue_free()
					_refresh_execute_button()
					return
			return

func _on_slot_clicked(idx: int) -> void:
	if current_state != State.SELECT:
		return
	var slot := slot_nodes[idx]
	if slot.is_empty():
		return
	var returned := slot.remove_card()
	var card_node := card_scene.instantiate() as CardUI
	hand_area.add_child(card_node)
	card_node.setup(returned)
	card_node.card_clicked.connect(_on_card_clicked)
	_refresh_execute_button()

func _on_execute_pressed() -> void:
	if current_state == State.SELECT:
		_change_state(State.EXECUTE)

# ── Helpers ────────────────────────────────────────────────────

func _refresh_execute_button() -> void:
	var has_card := false
	for slot in slot_nodes:
		if not slot.is_empty():
			has_card = true
			break
	execute_button.disabled = not has_card

func _check_result() -> bool:
	if enemy.current_hp <= 0:
		_show_result("Victory！")
		return true
	if player.current_hp <= 0:
		_show_result("Game Over...")
		return true
	return false

func _show_result(text: String) -> void:
	current_state = State.RESULT
	execute_button.disabled = true
	result_label.text = text
	result_label.visible = true
	_log("══ %s ══" % text)

func _update_ui() -> void:
	enemy_hp_bar.max_value = enemy.max_hp
	enemy_hp_bar.value     = enemy.current_hp
	enemy_label.text = "歌布靈戰士  HP: %d / %d" % [enemy.current_hp, enemy.max_hp]

	player_hp_bar.max_value = player.max_hp
	player_hp_bar.value     = player.current_hp
	player_hp_label.text = "HP: %d / %d" % [player.current_hp, player.max_hp]
	shield_label.text = "🛡 %d" % player.shield

func _log(msg: String) -> void:
	battle_log.append_text(msg + "\n")
