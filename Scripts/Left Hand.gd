extends Spatial

var mode = "frame"
var time_f = 10
var time_b = 0.1

func _ready():
	# map contains the bone id for each bone of the hand asset
	var map = {"wrist": 0,
	"thumb_tip": 25, "thumb_dst": 24, "thumb_pxm": 23, "thumb_mcp": 22,
	"index_tip": 21, "index_dst": 20, "index_int": 19, "index_pxm": 18,
	"middle_tip": 16, "middle_dst": 15, "middle_int": 14, "middle_pxm": 13,
	"ring_tip": 10, "ring_dst": 9, "ring_int": 8, "ring_pxm": 7,
	"little_tip": 5, "little_dst": 4, "little_int": 3, "little_pxm": 2}
	
	# Gets the keypoint data from the parsing script
	var data = get_node("/root/ImportData").getData()
	var frames = data["frames"]
	var conversionRatio = data["ratio"]
	
	var hand = get_node("/root/Main/LeftHand_11_26")
	var skel = get_node("Armature/Skeleton")
	var display_text = get_node("DisplayText")
	var bonePose
	
	for frame in frames:
		# get positions of bones needed to calculate hand orientation 
		var wrist = Vector3( frame["wrist"][0] , frame["wrist"][1] , frame["wrist"][2] )
		var middle_pxm = Vector3( frame["middle_pxm"][0] , frame["middle_pxm"][1] , frame["middle_pxm"][2] )
		var index_pxm = Vector3( frame["index_pxm"][0] , frame["index_pxm"][1] , frame["index_pxm"][2] )
		var little_pxm = Vector3( frame["little_pxm"][0] , frame["little_pxm"][1] , frame["little_pxm"][2] )
		var middle_tip = Vector3( frame["middle_tip"][0] , frame["middle_tip"][1] , frame["middle_tip"][2] )
		
		# the vector target is the direction the hand is facing
		# this is calculated using the middle proximal and wrist keypoint 
		# because hands are always facing that direction
		var vector_target = middle_pxm - wrist
		# the index proximal and little proximal are used to form a plane with the target vector
		var vector_forwards = index_pxm - little_pxm
		var vector_backwards = little_pxm - index_pxm
		# the palm is either facing in the vector_up_forwards or the vector_up_backwards direction
		var vector_up_forwards = vector_target.cross(vector_forwards)
		var vector_up_backwards = vector_target.cross(vector_backwards)
		var vector_up = Vector3()
		
		# the middle tip is the keypoint most likely to be in front of the palm
		var facing_direction = middle_pxm.direction_to(middle_tip)
		
		# find out the palm direction by taking the dot product of the up vector and the
		# direction to the middle tip
		if vector_up_forwards.dot(facing_direction) > 0:
			vector_up = vector_up_backwards
		else:
			vector_up = vector_up_forwards
		
		# point wrist in the right direction
		hand.look_at(hand.global_transform.origin + vector_target, vector_up)
		
		# the wrist translation is applied which moves the whole hand
		bonePose = skel.get_bone_global_pose(map["wrist"])
		var endPosition = Vector3( frame["wrist"][0] / conversionRatio , frame["wrist"][1] / conversionRatio , frame["wrist"][2] / conversionRatio)
		var newPose = Transform(bonePose.basis, skel.to_local(endPosition))
		skel.set_bone_global_pose_override(map["wrist"], newPose,1.0,true)
		
		var dict_key_array = Array(frame.keys())
		var bone_keys = Array()
		# the bone array must be reversed because the bones have to be moved from bottom to top
		for x in dict_key_array.size():
			var value = dict_key_array[-x-1]
			bone_keys.append(value)
		
		# these values are skipped because they can't be rotated
		var skip_names = ["dataset", "wrist", "thumb_tip", "index_tip", "middle_tip", "ring_tip", "little_tip"]
		
		# this shows the keypoints beside the hand
		var offset = Vector3(1, 0, 0)
		if get_node("/root/Main/Objects/Keypoint_View").visible:
			for bone in dict_key_array:
				if bone != "dataset":
					# get the position from the data, and move the keypoint meshinstance there
					var position = offset + Vector3((frame[bone][0])/conversionRatio,(frame[bone][1])/conversionRatio,(frame[bone][2])/conversionRatio)
					var keypoint = get_node("/root/Main/Objects/Keypoint_View/"+bone)
					keypoint.transform.origin = position
					keypoint.show()
		
		for bone in bone_keys.size():
			if not skip_names.has(bone_keys[bone]):
				# the bone keypoint used to calculate rotation angle and axis is the child of
				# the bone being rotated
				var next_bone = bone + 1
				
				# get positions of current bone location and next bone location on the hand asset
				# and the location of the next bone in the data which is the final location
				var pos1 = skel.to_global(skel.get_bone_global_pose(map[bone_keys[bone]]).origin)
				var pos2_i = skel.to_global(skel.get_bone_global_pose(map[bone_keys[next_bone]]).origin)
				var pos2_f = Vector3( frame[bone_keys[next_bone]][0] / conversionRatio , frame[bone_keys[next_bone]][1] / conversionRatio , frame[bone_keys[next_bone]][2] / conversionRatio )
				
				# the angle vectors are calculated
				var r_i = pos2_i - pos1
				var r_f = pos2_f - pos1
				var angle = r_i.angle_to(r_f)
				
				# the axis is perpendicular to the vectors making the angle
				var axis_global = r_f.cross(r_i)
				# the axis is calculated in global space so it has to be converted to local space
				var bone_to_global = skel.global_transform * skel.get_bone_global_pose(map[bone_keys[bone]])
				var axis_local = bone_to_global.basis.transposed() * axis_global

				bonePose = skel.get_bone_pose(map[bone_keys[bone]])
				bonePose = bonePose.rotated(axis_local.normalized(), angle)
				skel.set_bone_pose(map[bone_keys[bone]], bonePose)
			if mode == "bone":
				# this displays one bone at a time
				var data_txt = "Dataset Number: " + str(frame["dataset"])
				# update the display text
				display_text.set_text(data_txt)
				var t = Timer.new()
				t.set_wait_time(time_b)
				t.set_one_shot(true)
				self.add_child(t)
				t.start()
				yield(t, "timeout")
				t.queue_free()
		if mode == "frame":
			# this displays one frame at a time
			var data_txt = "Dataset Number: " + str(frame["dataset"])
			display_text.set_text(data_txt)
			var t = Timer.new()
			t.set_wait_time(time_f)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
