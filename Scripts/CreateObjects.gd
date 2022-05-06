# Creates cube objects.
extends Spatial


# Makes `amount` number of rigidbody cubes. The location and size can be randomized.
func create_cubes(amount: int, is_loc_random: bool, is_size_random: bool) -> void:
	for i in amount:
		# cube location
		var cube_location := Vector3()
		if is_loc_random:
			cube_location = random_vector(-2, 2)
		else:
			cube_location = Vector3(0, 1, 0)
		# cube size
		var cube_size := Vector3()
		if is_size_random:
			cube_size = random_vector(0.05, 0.2)
		else:
			cube_size = Vector3(0.1, 0.1, 0.1)
		# make rigidbody
		var cube_rigidbody := RigidBody.new()
		self.add_child(cube_rigidbody)
		cube_rigidbody.transform.origin = cube_location
		# all cubes are in this group for easy access
		cube_rigidbody.add_to_group("cubes")
		# make mesh
		var cube_mesh := MeshInstance.new()
		cube_mesh.mesh = CubeMesh.new()
		cube_mesh.mesh.set_size(cube_size)
		cube_rigidbody.add_child(cube_mesh)
		# set material
		var material := load(
			"res://Assets/KeypointMaterials/keypoint_little_material.tres"
		)
		cube_mesh.set_surface_material(0, material)
		# make collider
		var cube_collider := CollisionShape.new()
		cube_collider.set_shape(BoxShape.new())
		cube_collider.scale = cube_size
		cube_rigidbody.add_child(cube_collider)


# Returns a randomly generated Vector3 with values between `from` and `to`.
func random_vector(from: float, to: float) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return Vector3(
		rng.randf_range(from, to), rng.randf_range(from, to), rng.randf_range(from, to)
	)


# Removes all cubes from the scene.
func delete_cubes() -> void:
	var cubes := get_tree().get_nodes_in_group("cubes")
	for cube in cubes:
		cube.queue_free()
