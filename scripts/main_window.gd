extends Control

# node declarations
@onready var search_notes: LineEdit = $MarginContainer/VBoxContainer/MainUI/HSplitContainer/NoteList/VBoxContainer/SearchNotes
@onready var notes_container: VBoxContainer = $MarginContainer/VBoxContainer/MainUI/HSplitContainer/NoteList/VBoxContainer/ScrollContainer/NotesContainer
@onready var new_note: Button = $MarginContainer/VBoxContainer/MainUI/HSplitContainer/NoteList/VBoxContainer/GridContainer/NewNote
@onready var delete_note: Button = $MarginContainer/VBoxContainer/MainUI/HSplitContainer/NoteList/VBoxContainer/GridContainer/DeleteNote
@onready var notes_title: LineEdit = $MarginContainer/VBoxContainer/MainUI/HSplitContainer/VBoxContainer/HBoxContainer/NotesTitle
@onready var notes_editor: TextEdit = $MarginContainer/VBoxContainer/MainUI/HSplitContainer/VBoxContainer/NotesEditor
@onready var delete_note_confirm: ConfirmationDialog = $DeleteNoteConfirm
@onready var tag_bar: Panel = $MarginContainer/VBoxContainer/BottomBar/TagBar

# directory where notes will be saved to/loaded from
const NOTES_DIR: String = "user://notes/"

# path of the currently open note
var current_note_path: String = ""


func _ready() -> void:
	# automatically refresh notes list every 5 seconds
	var _refresh_timer := Timer.new()
	_refresh_timer.wait_time = 5.0
	_refresh_timer.timeout.connect(_on_refresh_timer_timeout)
	add_child(_refresh_timer)
	_refresh_timer.start()
	
	# make sure that notes directory exists
	DirAccess.make_dir_absolute(NOTES_DIR)
	
	# connect button signales
	new_note.pressed.connect(_create_note)
	delete_note.pressed.connect(func():
		delete_note_confirm.popup()
		delete_note_confirm.dialog_text = "Are you sure you want to delete:\n" + current_note_path
	)
	
	# connect other signals
	search_notes.text_changed.connect(_on_search_text_changed)
	notes_editor.text_changed.connect(_on_editor_text_changed)
	
	# load all notes into sidebar
	_load_notes()


func _load_notes(filter: String = "") -> void:
	# reset sidebar
	for child in notes_container.get_children():
		child.queue_free()
	
	# get all files in notes directory
	var dir = DirAccess.open(NOTES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var file_path: String = NOTES_DIR + file_name
				
				# extract note title from save file
				var file = FileAccess.open(file_path, FileAccess.READ)
				
				var data: Dictionary = JSON.parse_string(file.get_as_text())
				if not data:
					continue
				var file_title: String = data.get("title", "Untitled")
				var content: String = data.get("content", "")
				
				# create button for note in sidebar (allows searching)
				if filter == "" or file_title.to_lower().find(filter.to_lower()) != -1 or content.to_lower().find(filter.to_lower()) != -1:
					var file_button = Button.new()
					file_button.text = file_title
					file_button.focus_mode = Control.FOCUS_NONE
					file_button.pressed.connect(_open_note.bind(file_path))
					notes_container.add_child(file_button)
					file_button.add_theme_font_override("font", preload("res://assets/fonts/bahnschrift.ttf"))
				
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Failed to open directory")


func _open_note(note_path: String) -> void:
	current_note_path = note_path
	
	# get data from note file
	var file = FileAccess.open(note_path, FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	
	var title: String = data.get("title", "Untitled")
	var content: String = data.get("content", "")
	var tags = data.get("tags", [])
	
	# insert data from file into editor
	notes_title.text = title
	notes_editor.text = content
	
	# update tag bar
	tag_bar.current_note_tags.clear()
	for tag in tags:
		if not tag_bar.current_note_tags.has(tag):
			tag_bar.current_note_tags.append(tag)
	tag_bar._refresh_tags()


func _save_current_note() -> void:
	# make title valid
	var title = notes_title.text.strip_edges()
	if title == "":
		title = "Untitled"
	
	var file_name: String
	
	if current_note_path == "":
		# create new note
		var timestamp = str(Time.get_unix_time_from_system())
		file_name = NOTES_DIR + "_" + timestamp + ".json"
	else:
		# overwrite existing note
		file_name = current_note_path
	
	# create data to be saved to file
	var data = {
		"title": title,
		"content": notes_editor.text,
		"edited_at": Time.get_datetime_string_from_system(),
		"tags": tag_bar.current_note_tags
	}
	
	# save data to file
	var file = FileAccess.open(file_name, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data, "\t") # add tabs
		file.store_string(json_string)
		file.close()
		
		current_note_path = file_name
		_load_notes()
	else:
		push_error("Failed to save note to: " + file_name)


func _delete_current_note() -> void:
	var dir = DirAccess.open(NOTES_DIR)
	dir.remove(current_note_path)
	_create_note()
	_load_notes(search_notes.text)


func _create_note() -> void:
	# reset editor
	current_note_path = ""
	notes_title.text = "Untitled"
	notes_editor.text = ""
	tag_bar.current_note_tags.clear()
	tag_bar._refresh_tags()


func _on_search_text_changed(new_text: String) -> void:
	_load_notes(new_text)


func _on_editor_text_changed() -> void:
	_save_current_note()


func _on_refresh_timer_timeout() -> void:
	_load_notes(search_notes.text)
