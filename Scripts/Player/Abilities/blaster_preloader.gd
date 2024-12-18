extends ResourcePreloader


func load_blaster(new_blaster: int) -> PackedScene:
	if get_resource_list().size() > new_blaster:
		return get_resource(get_resource_list()[new_blaster])
	return null
