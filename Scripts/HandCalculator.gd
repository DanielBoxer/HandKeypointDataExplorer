extends Node
class_name HandCalculator


static func f_position(frame: Dictionary, key: String) -> Vector3:
	var output_position := Vector3(frame[key][0], frame[key][1], frame[key][2])
	return output_position


static func d_vector(start: Vector3, end: Vector3) -> Vector3:
	return end - start


static func calculate_rotation_angle(vector_start: Vector3, vector_end: Vector3) -> float:
	return vector_start.angle_to(vector_end)


static func calculate_palm_direction(
	hand_vector: Vector3,
	perpendicular_v1: Vector3,
	perpendicular_v2: Vector3,
	middle_tip: Vector3,
	middle_pxm: Vector3
) -> Vector3:
	# form a plane with the target vector, used for palm direction
	var hand_vector_forwards := perpendicular_v2 - perpendicular_v1
	var hand_vector_backwards := perpendicular_v1 - perpendicular_v2
	# palm is facing in the direction of either one up vector or the other
	var hand_vector_up_forwards := hand_vector.cross(hand_vector_forwards)
	var hand_vector_up_backwards := hand_vector.cross(hand_vector_backwards)
	var palm_direction := Vector3()
	# the middle tip is the keypoint most likely to be in front of the palm
	var hand_facing_direction := middle_pxm.direction_to(middle_tip)
	# find out the palm direction
	if hand_vector_up_forwards.dot(hand_facing_direction) > 0:
		palm_direction = hand_vector_up_backwards
	else:
		palm_direction = hand_vector_up_forwards
	return palm_direction


static func calculate_global_rotation_axis(vector1: Vector3, vector2: Vector3) -> Vector3:
	# the axis is perpendicular to the vectors making the angle
	return vector1.cross(vector2)


static func calculate_local_rotation_axis(
	hand_skeleton: Skeleton,
	keypoint: String,
	rotation_axis_global: Vector3,
	keypoint_map: Dictionary
) -> Vector3:
	var bone_to_global: Transform = (
		hand_skeleton.global_transform
		* hand_skeleton.get_bone_global_pose(keypoint_map[keypoint])
	)
	var rotation_axis_local: Vector3 = (
		bone_to_global.basis.transposed()
		* rotation_axis_global
	)
	return rotation_axis_local


static func reverse_array(input_array: Array) -> Array:
	var output_array := Array()
	for element in input_array.size():
		var current_element: String = input_array[-element - 1]
		output_array.append(current_element)
	return output_array
