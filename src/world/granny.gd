class_name Granny
extends Npc
## The (obviously a witch) grandma. Drives the requests (GDD "Pedidos da vó"):
## first visit gives the Vagalume; each delivered material becomes a pet.

const WHERE := {
	&"cogumelo": "No Bosque dos Cogumelos, a oeste da Floresta Escura. Leva a Vagalume pra clarear o caminho.",
	&"musgo": "No Pântano, a leste da floresta. A Barqueira atravessa o canal.",
	&"osso": "No cemitério, ao norte da floresta. A Toupeira cava por baixo da grade.",
}
const PET_NAMES := {&"barqueira": "Barqueira", &"toupeira": "Toupeira"}


## Pure plan for a conversation: what she says and what happens after.
## action: &"give_vagalume" | &"deliver" | &"" (just talk).
static func plan(stage: int, requested: StringName, has_requested: bool) -> Dictionary:
	if stage == 0:
		return {"action": &"give_vagalume", "lines": [
			"Ah, meu netinho! Chegou na hora certa.",
			"Preciso fazer um chazinho, mas faltam uns ingredientes...",
			"Leva essa Vagalume. Ela ilumina o caminho e morde... digo, ajuda.",
			"Primeiro, me traz um cogumelo. " + WHERE[&"cogumelo"],
		]}
	if requested == &"":
		return {"action": &"", "lines": ["Psiu, o chá tá no fogo. Volta daqui a pouquinho."]}
	if has_requested:
		return {"action": &"deliver", "lines": [
			"Isso! Exatamente o que eu precisava.",
			"(A vó joga o %s no caldeirão. Algo borbulha... e respira.)" % ItemCatalog.display_name(requested),
		]}
	return {"action": &"", "lines": [
		"Cadê o %s, querido?" % ItemCatalog.display_name(requested),
		WHERE.get(requested, ""),
	]}


static func after_delivery_lines(reward_pet: StringName, next_request: StringName) -> Array:
	var lines := []
	if reward_pet != &"":
		lines.append("Olha só quem acordou! A %s vai te acompanhar." % PET_NAMES.get(reward_pet, String(reward_pet)))
		lines.append("Pra trocar de pet, é só mexer no caldeirão.")
	if next_request != &"":
		lines.append("Agora preciso de %s. %s" % [ItemCatalog.display_name(next_request), WHERE.get(next_request, "")])
	else:
		lines.append("Agora sim... o chá está quase pronto. Senta aí, querido.")
	return lines


func interact(hero: Node) -> void:
	if hero is Node2D:
		_sprite.flip_h = (hero as Node2D).global_position.x < global_position.x
	var requested := GameState.requested_item()
	var conversation := plan(GameState.quest_stage, requested, GameState.has_item(requested))
	Dialogue.say(_speech(conversation.lines))
	await Dialogue.finished
	match conversation.action:
		&"give_vagalume":
			GameState.quest_stage = 1
			GameState.unlock_pet(&"vagalume")
			get_tree().call_group(&"game", &"set_active_pet", &"vagalume")
			_magic()
		&"deliver":
			var reward := GameState.deliver_requested()
			_magic()
			Dialogue.say(_speech(after_delivery_lines(reward, GameState.requested_item())))


func _magic() -> void:
	var at := global_position + Vector2(0, -8)
	for cauldron: Node2D in get_tree().get_nodes_in_group(&"cauldron"):
		at = cauldron.global_position + Vector2(0, -10)
	Fx.sfx(&"flash")
	Fx.ring(at, 40.0, Color(0.6, 1.0, 0.7), 0.6)
	Fx.burst(at, Color(0.6, 1.0, 0.7), 16, 70.0)
	Fx.shake(0.2)
