#include <pebble.h>
#include "netdownload.h"
#ifdef PBL_PLATFORM_APLITE
#include "png.h"
#endif

enum {
    CMD_KEY = 0x0, // TUPLE_INTEGER
};

enum {
    CMD_UP = 0x01,
    CMD_DOWN = 0x02,
    CMD_SINGLE_CLICK = 0x03,
    CMD_LONG_CLICK = 0x04,
};

#define APP_CONNECT_KEY 0x0
#define APP_SELECT_CAMERA_KEY 0x1
#define APP_SELECT_FLASH_KEY 0x2
#define APP_VIBRATE_MODE_KEY 0x3
#define APP_TAP_MODE_KEY 0x4
#define APP_CAMERA_PREVIEW_KEY 0x5
// 6,7,8 are for live preview - defined in netimage.h
#define APP_VIDEO_MODE_KEY 0x9

#define APP_VERSION_MAJOR 2
#define APP_VERSION_MINOR 1

static Window *window;
static TextLayer *text_layer;
static ActionBarLayer *action_bar;
static BitmapLayer *camera_preview_layer;
static GBitmap *camera_preview_bitmap;

bool in_focus = false;


#define MSG_TIME 1500
AppTimer* msg_timer;

GBitmap *icon_camera;
GBitmap *icon_front_camera;
GBitmap *icon_back_camera;
GBitmap *icon_flash_auto;
GBitmap *icon_flash_off;
GBitmap *icon_flash_on;
GBitmap *icon_video_camera;

static bool vibrateMode;
static bool tapMode;
static bool videoMode = false;
static bool callbacks_registered;

#define VIBRATE_SHORT_PULSE 1
#define VIBRATE_LONG_PULSE 2
#define VIBRATE_DOUBLE_PULSE 3


static void vibrateWatch(int mode) {

    if(vibrateMode) {
        switch (mode) {
            case VIBRATE_SHORT_PULSE:
                vibes_short_pulse();
                break;
                
            case VIBRATE_LONG_PULSE:
                vibes_long_pulse();
                break;
                
            case VIBRATE_DOUBLE_PULSE:
                vibes_double_pulse();
                break;
                
            default:
                break;
        }
    }

}

static void set_status(const char* msg, bool useTimer);

static void msg_timer_callback() {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "msg_timer_callback - BEGIN");
    if(videoMode) {
   		set_status("Long Press:\nSTOP video recording\nShort Press:\nSNAP a photo", false);
    }
    else {
	    set_status("Short Press:\nSNAP a photo\nLong Press:\nSTART video recording", false);
    }
    app_timer_cancel(msg_timer);
}

void download_complete_handler(NetDownload *download) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "download_complete_handler - BEGIN");
    printf("Loaded image with %lu bytes", download->length);
    printf("Heap free is %u bytes", heap_bytes_free());

#ifdef PBL_PLATFORM_APLITE
    GBitmap *bmp = gbitmap_create_with_data(download->data);
    bmp->bounds = GRect(0,0,128,128);
    bmp->row_size_bytes = 16;
    bmp->info_flags = 4096;    
#else
    GBitmap *bmp = gbitmap_create_from_png_data(download->data, download->length);
#endif
    bitmap_layer_set_bitmap(camera_preview_layer, bmp);

    // Save pointer to currently shown bitmap (to free it)
    if (camera_preview_bitmap) {
        gbitmap_destroy(camera_preview_bitmap);
    }
    camera_preview_bitmap = bmp;

    // Free the memory now
#ifdef PBL_PLATFORM_APLITE
    // gbitmap_create_with_png_data will free download->data
    free(download->data);
#else
    free(download->data);
#endif
    // We null it out now to avoid a double free
    download->data = NULL;
    netdownload_destroy(download);
}

static void set_status(const char* msg, bool useTimer) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "set_status - BEGIN");
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "msg = %s", msg);

    layer_set_hidden((Layer *)text_layer, false);
    text_layer_set_text(text_layer, msg);
    if(useTimer == true) {
        msg_timer = app_timer_register(MSG_TIME, msg_timer_callback, NULL);
    }
    else {
        app_timer_cancel(msg_timer);
    }
}

static void app_send_failed(DictionaryIterator* failed, AppMessageResult reason, void* context) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "app_send_failed - BEGIN");
    if(reason != APP_MSG_OK) {
        set_status("Oops! There was a problem, check your connection.", false);
    }
}



static void app_received_msg(DictionaryIterator* received, void* context) {
    // camera images are handled first
    layer_set_hidden((Layer *)text_layer, true);
    netdownload_receive(received, context);

    Tuple* tuple = dict_find(received, APP_CONNECT_KEY);
    if(tuple && (tuple->value->uint8 == 1)) {
        set_status("Connected to WatchCam!", true);
        vibrateWatch(VIBRATE_SHORT_PULSE);
    }
    else if(tuple && (tuple->value->uint8 == 0)) {
        set_status("Disconnected from WatchCam!", false);
        vibrateWatch(VIBRATE_DOUBLE_PULSE);
    }
    
    tuple = dict_find(received, APP_SELECT_CAMERA_KEY);
    if(tuple) {
        if(tuple->value->uint8 == 0) {
            action_bar_layer_set_icon(action_bar, BUTTON_ID_UP, icon_back_camera);
            set_status("Back facing camera selected", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
        else if(tuple->value->uint8 == 1) {
            action_bar_layer_set_icon(action_bar, BUTTON_ID_UP, icon_front_camera);
            set_status("Front facing camera selected", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
    }
    tuple = dict_find(received, APP_SELECT_FLASH_KEY);
    if(tuple) {
        if(tuple->value->uint8 == 0) {
            action_bar_layer_set_icon(action_bar, BUTTON_ID_DOWN, icon_flash_off);
            set_status("Flash mode is OFF", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
        else if(tuple->value->uint8 == 1) {
            action_bar_layer_set_icon(action_bar, BUTTON_ID_DOWN, icon_flash_on);
            set_status("Flash mode is ON", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
        else if(tuple->value->uint8 == 2) {
            action_bar_layer_set_icon(action_bar, BUTTON_ID_DOWN, icon_flash_auto);
            set_status("Flash mode is AUTO", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
    }
    tuple = dict_find(received, APP_VIBRATE_MODE_KEY);
    if(tuple) {
        if(tuple->value->uint8 == 0) {
            vibrateMode = false;
            set_status("Vibrate mode OFF", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
        else if(tuple->value->uint8 == 1) {
            vibrateMode = true;
            set_status("Vibrate mode ON", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
    }     
    tuple = dict_find(received, APP_TAP_MODE_KEY);
    if(tuple) {
        if(tuple->value->uint8 == 0) {
            tapMode = false;
            set_status("Tap to Snap mode OFF", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
        else if(tuple->value->uint8 == 1) {
            tapMode = true;
            set_status("Tap to Snap mode ON", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
    }     
    tuple = dict_find(received, APP_VIDEO_MODE_KEY);
    if(tuple) {
        if(tuple->value->uint8 == 0) {
            videoMode = false;
	        action_bar_layer_set_icon(action_bar, BUTTON_ID_SELECT, icon_camera);
            set_status("Video Recording OFF", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
        else if(tuple->value->uint8 == 1) {
            videoMode = true;
	        action_bar_layer_set_icon(action_bar, BUTTON_ID_SELECT, icon_video_camera);
            set_status("Video Recording ON", true);
            vibrateWatch(VIBRATE_LONG_PULSE);
        }
    }
}

bool register_callbacks() {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "register_callbacks - BEGIN");
	if (callbacks_registered) {
		app_message_deregister_callbacks();
		callbacks_registered = false;
        APP_LOG(APP_LOG_LEVEL_DEBUG, "deregisterd");
	}
	if (!callbacks_registered) {
    
        app_message_register_inbox_received(app_received_msg);
        app_message_register_outbox_failed(app_send_failed);

        APP_LOG(APP_LOG_LEVEL_DEBUG, "Max buffer sizes are %li / %li", app_message_inbox_size_maximum(), app_message_outbox_size_maximum());
        app_message_open(app_message_inbox_size_maximum(), app_message_outbox_size_maximum());
        callbacks_registered = true;
        APP_LOG(APP_LOG_LEVEL_DEBUG, "registered");
	}
	return callbacks_registered;
}

static void send_cmd(uint8_t cmd) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s - %d", "send_cmd - BEGIN", cmd);
    if(!in_focus) {
        app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "Will not send command, not in focus!");
        return;
    }

    Tuplet value = TupletInteger(CMD_KEY, cmd);
    
    DictionaryIterator *iter;
    app_message_outbox_begin(&iter);
    
    if (iter == NULL)
        return;
    
    dict_write_tuplet(iter, &value);
    dict_write_end(iter);
    
    app_message_outbox_send();
}

// Modify these common button handlers

void up_single_click_handler(ClickRecognizerRef recognizer, void *contex) {
    (void)recognizer;
    (void)window;
    
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "up_single_click_handler - BEGIN");
    send_cmd(CMD_UP);
}


void down_single_click_handler(ClickRecognizerRef recognizer, void *contex) {
    (void)recognizer;
    (void)window;

    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "down_single_click_handler - BEGIN");
    send_cmd(CMD_DOWN);
}


void select_single_click_handler(ClickRecognizerRef recognizer, void *contex) {
    (void)recognizer;
    (void)window;

    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "select_single_click_handler - BEGIN");
    
    set_status("Oh, Snap! Press the camera button to take another photo", true);
    send_cmd(CMD_SINGLE_CLICK);
}


void select_long_click_handler(ClickRecognizerRef recognizer, void *contex) {
    (void)recognizer;
    (void)window;

    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "select_long_click_handler - BEGIN");
    send_cmd(CMD_LONG_CLICK);
    if(videoMode) {
	    set_status("Turning OFF video recording", true);
    }
    else {
	    set_status("Turning ON video recording", true);
    }
}


// This usually won't need to be modified

void click_config_provider(void *context) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "click_config_provider - BEGIN");
    

    window_single_click_subscribe(BUTTON_ID_SELECT, select_single_click_handler);
    window_long_click_subscribe(BUTTON_ID_SELECT, 1000, select_long_click_handler, NULL /* No handler on button release */);


    window_set_click_context(BUTTON_ID_UP, context);
    window_single_repeating_click_subscribe(BUTTON_ID_UP, 100, up_single_click_handler);

    window_set_click_context(BUTTON_ID_DOWN, context);
    window_single_repeating_click_subscribe(BUTTON_ID_DOWN, 100, down_single_click_handler);
}


void window_load(Window *window) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "window_load - BEGIN");

    Layer *window_layer = window_get_root_layer(window);

#ifdef PBL_PLATFORM_APLITE
    camera_preview_layer = bitmap_layer_create(GRect(0,24,128,128));
    text_layer =  text_layer_create(GRect(0,0,128,168));
#else
    camera_preview_layer = bitmap_layer_create(GRect(0,0,120,168));
    text_layer =  text_layer_create(GRect(0,0,120,168));
#endif

    layer_add_child(window_layer, bitmap_layer_get_layer(camera_preview_layer));    
    camera_preview_bitmap = NULL;

    text_layer_set_text_color(text_layer, GColorWhite);
    text_layer_set_background_color(text_layer, GColorBlack);
    text_layer_set_overflow_mode(text_layer, GTextOverflowModeWordWrap);
    text_layer_set_font(text_layer, fonts_get_system_font(FONT_KEY_GOTHIC_24_BOLD));
    text_layer_set_text_alignment(text_layer, GTextAlignmentCenter);
    text_layer_set_text(text_layer, "Open WatchCam on your Mobile Device");
    layer_add_child(window_layer, text_layer_get_layer(text_layer));

    icon_camera = gbitmap_create_with_resource(RESOURCE_ID_CAMERA);
    icon_front_camera = gbitmap_create_with_resource(RESOURCE_ID_FRONT_CAMERA);
    icon_back_camera = gbitmap_create_with_resource(RESOURCE_ID_BACK_CAMERA);
    icon_flash_auto = gbitmap_create_with_resource(RESOURCE_ID_FLASH_AUTO);
    icon_flash_on = gbitmap_create_with_resource(RESOURCE_ID_FLASH_ON);
    icon_flash_off = gbitmap_create_with_resource(RESOURCE_ID_FLASH_OFF);
    icon_video_camera = gbitmap_create_with_resource(RESOURCE_ID_VIDEO_CAMERA);
    
    
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "window_load - create action bar");
    // Initialize the action bar:
    action_bar = action_bar_layer_create();
    // Associate the action bar with the window:
    action_bar_layer_add_to_window(action_bar, window);
    // Set the click config provider:
    action_bar_layer_set_click_config_provider(action_bar,
                                               click_config_provider);
    
    action_bar_layer_set_icon(action_bar, BUTTON_ID_UP, icon_back_camera);
    action_bar_layer_set_icon(action_bar, BUTTON_ID_SELECT, icon_camera);
    action_bar_layer_set_icon(action_bar, BUTTON_ID_DOWN, icon_flash_auto);
}

// Deinitialize resources on window unload that were initialized on window load
void window_unload(Window *window) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "window_unload - BEGIN");
    
    gbitmap_destroy(icon_camera);
    gbitmap_destroy(icon_front_camera);
    gbitmap_destroy(icon_back_camera);
    gbitmap_destroy(icon_flash_auto);
    gbitmap_destroy(icon_flash_on);
    gbitmap_destroy(icon_flash_off);
    gbitmap_destroy(icon_video_camera);

    text_layer_destroy(text_layer);
    bitmap_layer_destroy(camera_preview_layer);
    gbitmap_destroy(camera_preview_bitmap);

    action_bar_layer_remove_from_window(action_bar);
}


void accel_tap_handler(AccelAxisType axis, int32_t direction) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s - axis = %d", "accel_tap_handler - BEGIN", axis);
    if ((axis == ACCEL_AXIS_Z || axis == ACCEL_AXIS_Y || axis == ACCEL_AXIS_X) && (tapMode == true)) {
        send_cmd(CMD_SINGLE_CLICK);
        set_status("Oh, Snap! Press the camera button to take another photo", true);
    }
}

void app_in_focus_handler(bool aoo_in_focus) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "app_in_focus_handler - BEGIN");
    in_focus = aoo_in_focus;
}


void bluetooth_connection_handler(bool connected) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s - connected = %d", "bluetooth_connection_handler - BEGIN", connected);
}



void handle_init(void) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "handle_init - BEGIN");

    char buff[32];
    snprintf(buff, sizeof(buff), "%s v%d.%d", "WatchCam", APP_VERSION_MAJOR, APP_VERSION_MINOR);

    // Need to initialize this first to make sure it is there when
    // the window_load function is called by window_stack_push.
    netdownload_initialize(download_complete_handler);

    window = window_create();
#ifdef PBL_SDK_2
  window_set_fullscreen(window, true);
#endif    
    window_set_window_handlers(window, (WindowHandlers){
        .load = window_load,
        .unload = window_unload,
    });
    window_stack_push(window, true /* Animated */);
    window_set_background_color(window, GColorBlack);

    accel_tap_service_subscribe(accel_tap_handler);
    
//     bluetooth_connection_service_subscribe(bluetooth_connection_handler);
    app_focus_service_subscribe(app_in_focus_handler);
    
    register_callbacks();

    in_focus = true;

    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "handle_init - END");
    
}

void handle_deinit(void) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "handle_deinit - BEGIN");
    accel_tap_service_unsubscribe();
    app_focus_service_unsubscribe();
    action_bar_layer_destroy(action_bar);
    netdownload_deinitialize(); 
    window_destroy(window);
}

int main(void) {
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "main - init");
    handle_init();
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "main - event loop");
    app_event_loop();
    app_log(APP_LOG_LEVEL_DEBUG, __FILE__, __LINE__, "%s", "main - deinit");
    handle_deinit();
}
