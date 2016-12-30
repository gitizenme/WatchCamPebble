

#define MAX_OUTGOING_SIZE 114 // This allows some overhead.


#define SETTING_USERNAME "username"
#define kbUsername ""

#define SETTING_PWD "pwd"
#define kbPwd ""

#define SETTING_USERID "userId"
#define kbUserId ""

#define SETTING_SESSIONID "sessionId"
#define kbSessionId ""

#define SETTING_FLASH_MODE "flashMode"
#define kbFlashModeDefault AVCaptureFlashModeAuto

#define SETTING_SELF_TIMER_SECONDS "selfTimerSeconds"
#define kbSelfTimerSecondsDefault 0

#define SETTING_LIVE_PREVIEW_TIMER_SECONDS "livePreviewTimerSeconds"
#define kbLivePreviewTimerSecondsDefault 2

#define SETTING_ADD_LOCATION_TO_PHOTOS "addLocationDataToPhotos"
#define kbAddLocationDataToPhotosKeyDefault false

#define SETTING_FIRST_TIME_USE "firstTimeUse"
#define kbFirstTimeUseDefault true

#define SETTING_ALREADY_INSTALLED_WATCH_APP "alreadyInstallWatchApp"
#define kbAlreadyInstallWatchApp false

#define SETTING_REMIND_START_WATCH_APP "remindStartWatchApp"
#define kbRemindStartWatchApp true

#define SETTING_REMIND_CONNECT_WATCH_APP "askUserToConnectPebbleWatchApp"
#define kbAskUserToConnectPebbleWatchApp true

#define SETTING_KEEPSCREENON "keepScreenOn"
#define kbKeepScreenOn false

#define SETTING_FOLLOWONTWITTER "followedOnTwitter"
#define kbFollowedOnTwitter false

#define SETTING_VIBRATE_WATCH "vibrateWatch"
#define kbVibrateWatch false

#define SETTING_TAP_MODE "tapMode"
#define kbTapMode false

#define SETTING_CAMERA_PREVIEW "cameraPreview"
#define kbCameraPreview false

#define SETTING_VIDEO_MODE "videoMode"
#define kbVideMode false


#define CMD_KEY 0x0 // TUPLE_INTEGER
#define CMD_UP 0x01 // change camera mode
#define CMD_DOWN 0x02 // change flash mode
#define CMD_SINGLE_CLICK 0x03 // take a picture
#define CMD_LONG_CLICK 0x04 // video mode

#define APP_CONNECT_KEY @(0x0) // 0 = disconnect or 1 = connect
#define APP_SELECT_CAMERA_KEY @(0x1) // 0 = back, 1 = front
#define APP_SELECT_FLASH_KEY @(0x2) // 0 = off, 1 = on
#define APP_VIBRATE_MODE_KEY @(0x3) // 0 = off, 1 = on, 2 = auto
#define APP_TAP_MODE_KEY @(0x4) // 0 = off, 1 = on
#define APP_CAMERA_PREVIEW_KEY @(0x5) // 0 = off, 1 = on

#define APP_IMAGE_DATA @(0x6) // MAX_OUTGOING_SIZE or less bytes
#define APP_IMAGE_BEGIN @(0x7) // parameter is the number of bytes in the image
#define APP_IMAGE_END @(0x8) // always pass ‘1'

#define APP_VIDEO_MODE_KEY @(0x9) // 0 = off, 1 = on


