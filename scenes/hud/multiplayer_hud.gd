extends CanvasLayer

@onready var scores_container: VBoxContainer = $ScoresContainer

func _ready() -> void:
	for id in NetManager.players:
		var label = Label.new()
		label.name = str(id)
		label.text = "%s: %06d" % [NetManager.players[id], 0]
		scores_container.add_child(label)
		
func update_score(player_id: int, score: int):
	var label = scores_container.get_node_or_null(str(player_id))
	if label:
		label.text = "%s: %06d" % [NetManager.players[player_id], score]
