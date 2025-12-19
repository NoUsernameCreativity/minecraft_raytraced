extends Node3D

@export var chunkBoxDimensions: Vector3 = Vector3(16, 64, 16)
@export var chunkRange: int = 2
@export var directionalLightSource: Light3D
@export var player: Node3D

@export var ChunkPostProcessedPrefab : PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for x in range(-chunkRange, chunkRange):
		for z in range(-chunkRange, chunkRange):
			if x*x + z*z >= chunkRange:
				continue
			var sceneInstance = ChunkPostProcessedPrefab.instantiate()
			sceneInstance.position = Vector3(chunkBoxDimensions.x * x, 0, chunkBoxDimensions.z * z)
			self.add_child(sceneInstance)
	
	# Sort the children nodes by depth to avoid sorting issues
	# This is caused because multiple passes are being done by different chunks
	# In post processing, but godot doesn't support writing to the depth map
	# between all of these multiple passes. So instead we sort them by depth
	# So that painters algo can handle the rest
	
	
	
	
	# Set non instance specific important uniforms
	self.get_child(0).get_active_material(0).set_shader_parameter("u_viewBoxDim", chunkBoxDimensions)
	self.get_child(0).get_active_material(0).set_shader_parameter("u_directionalSunDirection", -directionalLightSource.global_transform.basis.z)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		var sorted_children = self.get_children()
		sorted_children.sort_custom(
			func(a: Node3D, b: Node3D): 
				var da = a.global_transform.origin + chunkBoxDimensions / 2 - player.global_transform.origin
				var db = b.global_transform.origin + chunkBoxDimensions / 2 - player.global_transform.origin
				return db.length() < da.length()
		)
		
		for i in range(sorted_children.size()):
			var mat = sorted_children[i].get_active_material(0)
			mat.render_priority = i
		
		for child in sorted_children:
			self.remove_child(child)
		for child in sorted_children:
			self.add_child(child)
		
		print()
		for child in get_children():
			print(child.global_transform.origin)
