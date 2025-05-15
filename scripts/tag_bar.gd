extends Panel

@onready var tags_line: LineEdit = $VBoxContainer/GridContainer/TagsLine
@onready var add_tag_button: Button = $VBoxContainer/GridContainer/AddTagButton
@onready var tag_container: HFlowContainer = $VBoxContainer/ScrollContainer/TagContainer

const TAG: PackedScene = preload("res://scenes/tag.tscn")

var current_note_tags: Array[String] = []


func _ready() -> void:
	add_tag_button.pressed.connect(_on_add_tag_pressed)


func _on_add_tag_pressed() -> void:
	var new_tag = tags_line.text.strip_edges()
	if new_tag != "" and not current_note_tags.has(new_tag):
		current_note_tags.append(new_tag)
		_refresh_tags()
	tags_line.text = ""


func _refresh_tags() -> void:
	for child in tag_container.get_children():
		child.queue_free()
	
	for tag in current_note_tags:
		var tag_label = TAG.instantiate()
		tag_label.set_tag_name(tag)
		tag_container.add_child(tag_label)
