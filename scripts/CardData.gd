extends Node

# Dados recebidos do servidor
var card_data: Dictionary = {}

# Referências aos nós
@onready var cost_label:  Label       = $CostLabel
@onready var card_image:  TextureRect = $CardImage
@onready var name_label:  Label       = $NameLabel
@onready var text_label:  Label       = $TextLabel

# ─────────────────────────────────────────────────────────
# Chamado pelo Game.gd após instanciar a carta
# Recebe o dict vindo do JSON do servidor
func setup(data: Dictionary) -> void:
	card_data = data
	_render()

# ─────────────────────────────────────────────────────────
func _render() -> void:
	name_label.text = card_data.get("name", "???")
	cost_label.text = str(card_data.get("cost", 0))
	text_label.text = card_data.get("text", "")

	_load_card_image(card_data.get("id", 0))

# ─────────────────────────────────────────────────────────
func _load_card_image(card_id: int) -> void:
	# Monta o caminho baseado no ID — sem switch, sem dicionário
	var path = "res://assets/cards/%d.png" % card_id

	# Verifica se o arquivo existe antes de carregar
	if ResourceLoader.exists(path):
		card_image.texture = load(path)
	else:
		# Fallback: imagem padrão se o ID não tiver asset ainda
		card_image.texture = load("res://assets/cards/default.png")
		push_warning("Card: imagem não encontrada para ID %d" % card_id)
