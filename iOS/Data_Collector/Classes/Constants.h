//
//  Constants.h
//  iOS Data Collector
//
//  Created by Mike Stowell and Jeremy Poulin on 2/28/13.
//  Copyright 2013 iSENSE Development Team. All rights reserved.
//  Engaging Computing Lab, Advisor: Fred Martin
//

#ifndef Constants_h
#define Constants_h

// default sample interval
#define DEFAULT_SAMPLE_INTERVAL      125

// constants for dialogs
#define MENU_EXPERIMENT               0
#define MENU_LOGIN                    1
#define EXPERIMENT_MANUAL_ENTRY       118
#define CLEAR_FIELDS_DIALOG           3
#define MENU_UPLOAD                   4
#define DESCRIPTION_AUTOMATIC         5

// constants for manual dialog
#define MANUAL_MENU_UPLOAD            0
#define MANUAL_MENU_EXPERIMENT        1
#define MANUAL_MENU_LOGIN             2

// options for action sheet
#define OPTION_CANCELED                0
#define OPTION_ENTER_EXPERIMENT_NUMBER 1
#define OPTION_BROWSE_EXPERIMENTS      2
#define OPTION_SCAN_QR_CODE            3

// types of text field data
#define TYPE_DEFAULT   0
#define TYPE_LATITUDE  1
#define TYPE_LONGITUDE 2
#define TYPE_TIME      3

// ipad and iphone dimensions
#define IPAD_WIDTH_PORTRAIT     725
#define IPAD_WIDTH_LANDSCAPE    980
#define IPHONE_WIDTH_PORTRAIT   280
#define IPHONE_WIDTH_LANDSCAPE  415

// manual scrollview drawing constants
#define SCROLLVIEW_Y_OFFSET     50
#define SCROLLVIEW_OBJ_INCR     30
#define SCROLLVIEW_LABEL_HEIGHT 20
#define SCROLLVIEW_TEXT_HEIGHT  35
#define UI_FIELDNAME            0
#define UI_FIELDCONTENTS        1

// manual scrollview oddity patches
#define PORTRAIT_BOTTOM_CUT         40
#define LANDSCAPE_BOTTOM_CUT_IPAD   30
#define LANDSCAPE_BOTTOM_CUT_IPHONE 80
#define TOP_ELEMENT_ADJUSTMENT      30
#define START_Y_PORTRAIT_IPAD       20
#define START_Y_PORTRAIT_IPHONE     50
#define START_Y_LANDSCAPE_IPAD      5
#define START_Y_LANDSCAPE_IPHONE    0

// manual scrollview keyboard and other offset values
#define KEY_OFFSET_SCROLL_LAND_IPAD     40
#define KEY_OFFSET_SCROLL_PORT_IPHONE   18
#define KEY_OFFSET_FRAME_PORT_IPHONE    18
#define KEY_OFFSET_SCROLL_LAND_IPHONE   60
#define KEY_OFFSET_FRAME_LAND_IPHONE    90
#define KEY_HEIGHT_OFFSET               40
#define RECT_HEIGHT_OFFSET              30


// tags for types of UITextFields in Manual
#define TAG_DEFAULT 1000
#define TAG_TEXT    5000
#define TAG_NUMERIC 6000

// tags for the UITextFields in Automatic
#define TAG_AUTOMATIC_SESSION_TITLE   9001
#define TAG_AUTOMATIC_SAMPLE_INTERVAL 9002

// constants for moving Automatic's view up when keyboard present
#define KEY_OFFSET_SESSION_LAND_IPHONE  75
#define KEY_OFFSET_SAMPLE_LAND_IPHONE   75
#define KEY_OFFSET_SAMPLE_PORT_IPHONE   230
#define KEY_OFFSET_SAMPLE_PORT_IPAD     155

// nav controller height
#define NAVIGATION_CONTROLLER_HEIGHT 64

// waffle constants
#define WAFFLE_LENGTH_SHORT  2.0
#define WAFFLE_LENGTH_LONG   3.5
#define WAFFLE_BOTTOM @"bottom"
#define WAFFLE_TOP @"top"
#define WAFFLE_CENTER @"center"
#define WAFFLE_CHECKMARK @"waffle_check"
#define WAFFLE_RED_X @"waffle_x"
#define WAFFLE_WARNING @"waffle_warn"

// data recording constants
#define S_INTERVAL      125
#define TEST_LENGTH     600
#define MAX_DATA_POINTS (1000/S_INTERVAL) * TEST_LENGTH

// step one setup text field tags
#define TAG_STEP1_SESSION_NAME      1000
#define TAG_STEP1_SAMPLE_INTERVAL   1001
#define TAG_STEP1_TEST_LENGTH       1002

// delegate constants to determine the calling class
#define DELEGATE_KEY_AUTOMATIC  0
#define DELEGATE_KEY_MANUAL     1
#define DELELGATE_KEY_QUEUE     2

// constants for QueueUploaderView's actionSheet
#define QUEUE_DELETE        0
#define QUEUE_RENAME        1
#define QUEUE_SELECT_EXP    2
#define QUEUE_LOGIN         500

#endif
