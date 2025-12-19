extends MeshInstance3D

#Optimisation for the shader (small) by representing it as a triangle
@export var cubeDimensions : Vector3 = Vector3(16, 64, 16)

var finalImageTexture : ImageTexture3D

func _ready():
	randomize()
	
	# generate voxel data to write the a 3d image texture
	var voxelDataArray = []
	for x in range(0, cubeDimensions.x):
		var twoDimArray = []
		for y in range(0, cubeDimensions.y):
			var oneDimArray = []
			for z in range(0, cubeDimensions.z):
				if randf() < 0.01:
					oneDimArray.append(Vector3(1, 0, 0))
				else:
					oneDimArray.append(Vector3.ZERO)
			twoDimArray.append(oneDimArray)
		voxelDataArray.append(twoDimArray)
	
	
	# Generate voxel data from a 3D array
	var imageSlices = []
	for z in range(0, cubeDimensions.z):
		var image = Image.create_empty(cubeDimensions.x, cubeDimensions.y, false, Image.FORMAT_RGBA8)
		
		for x in range(0, cubeDimensions.x):
			for y in range(0, cubeDimensions.y):
				var colorData = voxelDataArray[x][y][z]
				image.set_pixel(x, y, Color(colorData.x, colorData.y, colorData.z, 0.0))
		
		imageSlices.append(image)
	
	
	finalImageTexture = ImageTexture3D.new()
	finalImageTexture.create(Image.FORMAT_RGBA8, cubeDimensions.x, cubeDimensions.y, cubeDimensions.z, false, imageSlices)
	
	# Instance is important here
	self.set_instance_shader_parameter("u_voxelDataTexture", finalImageTexture)
	self.set_instance_shader_parameter("u_viewBoxTransformOrigin", self.global_transform.origin)
	
	# optional code to save the image texture
	#if true:
		#ResourceSaver.save(finalImageTexture, "3d_texture.res")
		


func _process(delta: float) -> void:
	# how to update chunks. Decently fast so could work with fairly large chunks
	pass
	
	#if Input.is_action_just_pressed( "jump"):
		#var images : Array[Image] = finalImageTexture.get_data()
		#for x in range(0, cubeDimensions.x):
			#for y in range(0, cubeDimensions.y):
					#images[0].set_pixel(x, y, Color(1, 0, 0))
		#finalImageTexture.update(images)
