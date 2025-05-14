extends Control

# node declarations
@onready var notes_container: VBoxContainer = $VBoxContainer/MainUI/HSplitContainer/NoteList/VBoxContainer/ScrollContainer/NotesContainer
@onready var notes_title: LineEdit = $VBoxContainer/MainUI/HSplitContainer/VBoxContainer/NotesTitle
@onready var notes_editor: TextEdit = $VBoxContainer/MainUI/HSplitContainer/VBoxContainer/NotesEditor
@onready var save_note: Button = $VBoxContainer/MainUI/HSplitContainer/NoteList/VBoxContainer/GridContainer/SaveNote
@onready var new_note: Button = $VBoxContainer/MainUI/HSplitContainer/NoteList/VBoxContainer/GridContainer/NewNote

# directory where notes will be saved to/loaded from
const NOTES_DIR: String = "user://notes/"

# path of the currently open note
var current_note_path: String = ""

# list of allowed characters in file name
var allowed_characters: Array = [
	"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
	".", "_", "-", " ", "(", ")", ",",
]


func _ready() -> void:
	# automatically refresh notes list every 5 seconds
	var _refresh_timer := Timer.new()
	_refresh_timer.wait_time = 5.0
	_refresh_timer.timeout.connect(_load_notes)
	add_child(_refresh_timer)
	_refresh_timer.start()
	
	# make sure that notes directory exists
	DirAccess.make_dir_absolute(NOTES_DIR)
	
	# connect button signales
	save_note.pressed.connect(_save_current_note)
	new_note.pressed.connect(_create_note)
	
	# load all notes into sidebar
	_load_notes()


func _load_notes() -> void:
	# reset sidebar
	for child in notes_container.get_children():
		child.queue_free()
	
	# get all files in notes directory
	var dir = DirAccess.open(NOTES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var file_path = NOTES_DIR + file_name
				
				# remove .json from sidebar
				var base_name = file_name.replace(".json", "")
				
				# remove timestamp from sidebar
				var parts = base_name.split("_")
				if parts.size() > 1:
					parts.remove_at(parts.size() - 1)
					base_name = "_".join(parts)
				
				# create button for note in sidebar
				var file_button = Button.new()
				file_button.text = base_name
				file_button.focus_mode = Control.FOCUS_NONE
				file_button.pressed.connect(_open_note.bind(file_path))
				notes_container.add_child(file_button)
				
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		push_error("Failed to open directory")


func _open_note(note_path: String) -> void:
	current_note_path = note_path
	
	# get data from note file
	var file = FileAccess.open(note_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	var title = data.get("title", "")
	var content = data.get("content", "")
	
	# insert data from file into editor
	notes_title.text = title
	notes_editor.text = content


func _save_current_note() -> void:
	# make title valid
	var title = notes_title.text.strip_edges()
	if title == "":
		title = "Untitled"
	
	var file_name: String
	
	if current_note_path == "":
		# create new note
		var safe_title: String = title
		for character in title:
			if not allowed_characters.has(character):
				safe_title = title.replace(character, "")
		#var safe_title = title.replace(" ", "_")
		var timestamp = str(Time.get_unix_time_from_system())
		file_name = NOTES_DIR + safe_title + "_" + timestamp + ".json"
	else:
		# overwrite existing note
		file_name = current_note_path
	
	# create data to be saved to file
	var data = {
		"title": title,
		"content": notes_editor.text,
		"created_at": Time.get_datetime_string_from_system()
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


func _create_note() -> void:
	# reset editor
	current_note_path = ""
	notes_title.text = "Untitled"
	notes_editor.text = ""
