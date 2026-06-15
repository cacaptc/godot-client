extends Node

# Referências aos nós da UI
@onready var status_label   = $"../StatusLabel"
@onready var card_label     = $"../CardLabel"
@onready var message_label  = $"../MessageLabel"
@onready var draw_button    = $"../DrawCardButton"

# O cliente WebSocket do Godot 4
var socket = WebSocketPeer.new()
var server_url = "ws://localhost:8080/ws"

# Estado da conexão
enum State { DISCONNECTED, CONNECTING, CONNECTED }
var current_state = State.DISCONNECTED
const CardScene = preload("res://scenes/card.tscn")

@onready var hand_container = $"../HandContainer" # HBoxContainer onde as cartas aparecem
# ─────────────────────────────────────────────
func _ready():
	draw_button.pressed.connect(_on_draw_card_pressed)
	draw_button.disabled = true  # desabilita até conectar
	_connect_to_server()

# ─────────────────────────────────────────────
func _connect_to_server():
	status_label.text = "🔄 Conectando..."
	var err = socket.connect_to_url(server_url)
	if err != OK:
		status_label.text = "❌ Falha ao conectar"
		return
	current_state = State.CONNECTING

# ─────────────────────────────────────────────
# _process roda a cada frame — é aqui que "escutamos" o servidor
func _process(_delta):
	# Atualiza o estado interno do socket
	socket.poll()

	var state = socket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			# Acabou de conectar?
			if current_state != State.CONNECTED:
				current_state = State.CONNECTED
				status_label.text = "✅ Conectado ao servidor"
				draw_button.disabled = false

			# Lê todas as mensagens disponíveis no buffer
			while socket.get_available_packet_count() > 0:
				var packet = socket.get_packet()
				var text = packet.get_string_from_utf8()
				_handle_server_message(text)

		WebSocketPeer.STATE_CLOSED:
			if current_state != State.DISCONNECTED:
				current_state = State.DISCONNECTED
				status_label.text = "🔴 Desconectado"
				draw_button.disabled = true

# ─────────────────────────────────────────────
func _on_draw_card_pressed():
	# Monta o JSON e envia para o servidor
	var message = {
		"type": "player_action",
		"action": "draw_card"
	}
	var json_string = JSON.stringify(message)
	socket.send_text(json_string)

# ─────────────────────────────────────────────
func _handle_server_message(text: String):
	var json = JSON.new()
	if json.parse(text) != OK:
		return

	var data = json.get_data()

	match data.get("type", ""):
		"card_drawn":
			_spawn_card(data.get("card", {}))


		"deck_empty":
			card_label.text    = "🃏 —"
			message_label.text = "⚠️ Baralho vazio!"

		"error":
			message_label.text = "❌ " + data.get("message", "")
			
func _spawn_card(card_data: Dictionary) -> void:
	var card = CardScene.instantiate()    # cria instância da cena
	hand_container.add_child(card)        # adiciona na mão
	card.setup(card_data)
