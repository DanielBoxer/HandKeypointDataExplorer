#include <gdnative_api_struct.gen.h>

static int random_seed = 0;

static const char* sample_keypoints[21] = 
{
    "wrist",
    "thumb_tip",
    "thumb_dst",
    "thumb_pxm",
    "thumb_mcp",
    "index_tip",
    "index_dst",
    "index_int",
    "index_pxm",
    "middle_tip",
    "middle_dst",
    "middle_int",
    "middle_pxm",
    "ring_tip",
    "ring_dst",
    "ring_int",
    "ring_pxm",
    "little_tip",
    "little_dst",
    "little_int",
    "little_pxm",
};

static float sample_keypoint_data[5][21][3] =
{
    {
        {-0.00488, -0.05724, 0.7018},
        {-0.01406, 0.03035, 0.5829} ,
        {-0.02056, 0.01356, 0.6067} ,
        {-0.02833, -0.01342, 0.6344} ,
        {-0.02037, -0.0345, 0.6679} ,
        {0.01981, 0.0278, 0.5292} ,
        {0.01434, 0.01526, 0.5475} ,
        {0.007658, -0.003428, 0.5729} ,
        {-0.001645, -0.02029, 0.6021} ,
        {0.02355, 0.06246, 0.5643} ,
        {0.02565, 0.03507, 0.5711} ,
        {0.02679, 0.008805, 0.5783} ,
        {0.02054, -0.01729, 0.6071} ,
        {0.0355, 0.05862, 0.5791} ,
        {0.03781, 0.03081, 0.5893} ,
        {0.03916, 0.007767, 0.5961} ,
        {0.03463, -0.01549, 0.6197} ,
        {0.0599, 0.04777, 0.5969} ,
        {0.06011, 0.03241, 0.6036} ,
        {0.05921, 0.01552, 0.6101} ,
        {0.04836, -0.01112, 0.639}
    },
    {
        {0.001013, -0.1528, 0.4608},
        {0.0473, -0.04534, 0.4218} ,
        {0.04475, -0.06748, 0.4251} ,
        {0.04042, -0.09568, 0.4282} ,
        {0.0232, -0.128, 0.442} ,
        {0.03253, 0.01401, 0.4432} ,
        {0.03661, -0.009772, 0.4525} ,
        {0.0383, -0.03238, 0.4597} ,
        {0.0364, -0.06765, 0.4585} ,
        {-0.003463, -0.004862, 0.4187} ,
        {0.00571, -0.01545, 0.4432} ,
        {0.01564, -0.03228, 0.4647} ,
        {0.01909, -0.06418, 0.47} ,
        {-0.02179, -0.05551, 0.4157} ,
        {-0.0158, -0.04287, 0.4369} ,
        {-0.006543, -0.0423, 0.4618} ,
        {0.002344, -0.06819, 0.4738} ,
        {-0.03412, -0.07772, 0.4283} ,
        {-0.03373, -0.06167, 0.4422} ,
        {-0.02851, -0.05696, 0.4584} ,
        {-0.01743, -0.07671, 0.4727}
    },
    {
        {-0.05453, -0.002965, 0.6191} ,
        {-0.1182, 0.1114, 0.5491} ,
        {-0.1042, 0.08703, 0.5593} ,
        {-0.0936, 0.04991, 0.5674} ,
        {-0.07817, 0.02179, 0.5919} ,
        {-0.1108, 0.07449, 0.5853} ,
        {-0.1111, 0.09564, 0.5766} ,
        {-0.0897, 0.1095, 0.557} ,
        {-0.07011, 0.08066, 0.5551} ,
        {-0.1014, 0.09502, 0.5895} ,
        {-0.09914, 0.1216, 0.5802} ,
        {-0.07599, 0.1267, 0.5667} ,
        {-0.05878, 0.0917, 0.5717} ,
        {-0.0765, 0.06242, 0.6109} ,
        {-0.08843, 0.08954, 0.6129} ,
        {-0.07918, 0.1088, 0.6018} ,
        {-0.0525, 0.09281, 0.5896} ,
        {-0.07993, 0.07304, 0.6335} ,
        {-0.08566, 0.08741, 0.6398} ,
        {-0.08044, 0.1043, 0.6359} ,
        {-0.04911, 0.09109, 0.6134}
    },
    {
        {-0.03309, 0.1237, 0.5917} ,
        {-0.1417, 0.06847, 0.5008} , 
        {-0.1222, 0.08091, 0.5197} , 
        {-0.0984, 0.09504, 0.5478} , 
        {-0.06893, 0.112, 0.5697} , 
        {-0.1264, 0.03708, 0.4511} , 
        {-0.1169, 0.03921, 0.4718} , 
        {-0.1033, 0.04557, 0.5003} , 
        {-0.09035, 0.05845, 0.5301} , 
        {-0.1083, 0.02986, 0.4377} , 
        {-0.09614, 0.03333, 0.463} , 
        {-0.08503, 0.03775, 0.4875} , 
        {-0.0704, 0.05629, 0.519} , 
        {-0.08601, 0.03908, 0.4384} , 
        {-0.07355, 0.04399, 0.4649} , 
        {-0.06449, 0.04847, 0.4867} , 
        {-0.05294, 0.06261, 0.5148} , 
        {-0.05845, 0.05116, 0.4439} , 
        {-0.05159, 0.05585, 0.4585} , 
        {-0.04514, 0.05932, 0.475} , 
        {-0.03317, 0.07564, 0.5105}
    },
    {
        {0.1034, 0.1237, 0.607} ,
        {0.0779, 0.009581, 0.5989} ,
        {0.08341, 0.0261, 0.6131} ,
        {0.08732, 0.05133, 0.6262} ,
        {0.09724, 0.08893, 0.6216} ,
        {0.1199, -0.04678, 0.5682} ,
        {0.1198, -0.02264, 0.5775} ,
        {0.1209, 4.061e-05, 0.5846} ,
        {0.1144, 0.03273, 0.5963} ,
        {0.0456, 0.01718, 0.5774} ,
        {0.07072, 0.00962, 0.5671} ,
        {0.09943, 0.01298, 0.5644} ,
        {0.1151, 0.03894, 0.5762} ,
        {0.04872, 0.04383, 0.5715} ,
        {0.06666, 0.03119, 0.5588} ,
        {0.09226, 0.02911, 0.5519} ,
        {0.1099, 0.05014, 0.5636} ,
        {0.05535, 0.06862, 0.565} ,
        {0.06374, 0.05535, 0.5506} ,
        {0.07924, 0.0507, 0.5436} ,
        {0.09927, 0.0657, 0.5532}
    }
};

const godot_gdnative_core_api_struct* api = NULL;
const godot_gdnative_ext_nativescript_api_struct* nativescript_api = NULL;

void* keypoints_constructor(godot_object* p_instance, void* p_method_data);
void keypoints_destructor(godot_object* p_instance, void* p_method_data, void* p_user_data);
godot_variant keypoints_get_data(godot_object* p_instance, void* p_method_data,
    void* p_user_data, int p_num_args, godot_variant** p_args);

void GDN_EXPORT godot_gdnative_init(godot_gdnative_init_options* p_options) {
    api = p_options->api_struct;

    // find extensions
    for (int i = 0; i < api->num_extensions; i++) {
        switch (api->extensions[i]->type) {
        case GDNATIVE_EXT_NATIVESCRIPT: {
            nativescript_api = (godot_gdnative_ext_nativescript_api_struct*)api->extensions[i];
        }; break;
        default: break;
        }
    }
}

void GDN_EXPORT godot_gdnative_terminate(godot_gdnative_terminate_options* p_options) {
    api = NULL;
    nativescript_api = NULL;
}

void GDN_EXPORT godot_nativescript_init(void* p_handle) {
    godot_instance_create_func create = { NULL, NULL, NULL };
    create.create_func = &keypoints_constructor;

    godot_instance_destroy_func destroy = { NULL, NULL, NULL };
    destroy.destroy_func = &keypoints_destructor;

    nativescript_api->godot_nativescript_register_class(p_handle, "KEYPOINTS", "Reference",
        create, destroy);

    godot_instance_method get_data = { NULL, NULL, NULL };
    get_data.method = &keypoints_get_data;

    godot_method_attributes attributes = { GODOT_METHOD_RPC_MODE_DISABLED };

    nativescript_api->godot_nativescript_register_method(p_handle, "KEYPOINTS", "get_data",
        attributes, get_data);
}

typedef struct user_data_struct {
    int placeholder;
} user_data_struct;

void* keypoints_constructor(godot_object* p_instance, void* p_method_data) {
    user_data_struct* user_data = api->godot_alloc(sizeof(user_data_struct));
    return user_data;
}

void keypoints_destructor(godot_object* p_instance, void* p_method_data, void* p_user_data) {
    api->godot_free(p_user_data);
}

godot_variant keypoints_get_data(godot_object* p_instance, void* p_method_data,
    void* p_user_data, int p_num_args, godot_variant** p_args) {

    godot_array godot_final_array;
    godot_variant ret;
    godot_variant keypoint;

    user_data_struct* user_data = (user_data_struct*)p_user_data;

    // generate random frame number
    srand(random_seed);
    int next_frame = rand() % 5;

    // create array
    api->godot_array_new(&godot_final_array);

    // populate array
    for (int hand_keypoint = 0; hand_keypoint < 21; hand_keypoint++) {
        // make godot vector3 with sample keypoint data
        godot_vector3 vec3_keypoint;
        api->godot_vector3_set_axis(&vec3_keypoint, GODOT_VECTOR3_AXIS_X, sample_keypoint_data[next_frame][hand_keypoint][0]);
        api->godot_vector3_set_axis(&vec3_keypoint, GODOT_VECTOR3_AXIS_Y, sample_keypoint_data[next_frame][hand_keypoint][1]);
        api->godot_vector3_set_axis(&vec3_keypoint, GODOT_VECTOR3_AXIS_Z, sample_keypoint_data[next_frame][hand_keypoint][2]);

        // add keypoint string to array
        godot_string key;
        godot_variant key_variant;
        api->godot_string_new(&key);
        api->godot_string_parse_utf8(&key, sample_keypoints[hand_keypoint]);
        api->godot_variant_new_string(&key_variant, &key);
        api->godot_string_destroy(&key);
        api->godot_array_push_back(&godot_final_array, &key_variant);

        // add vector3 to array
        api->godot_variant_new_vector3(&keypoint, &vec3_keypoint);
        api->godot_array_push_back(&godot_final_array, &keypoint);
    }

    // change random number seed
    random_seed++;

    // set return array
    api->godot_variant_new_array(&ret, &godot_final_array);
    api->godot_array_destroy(&godot_final_array);
    api->godot_variant_destroy(&keypoint);
    

    return ret;
}
