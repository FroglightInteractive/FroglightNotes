extends Panel


func set_image(image: Image) -> void:
	var image_tex = ImageTexture.create_from_image(image)
	$TextureRect.texture = image_tex


func set_image_title(text: String) -> void:
	tooltip_text = text
