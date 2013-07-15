//
//  ViewController.m
//  Car Ramp Physics
//
//  Created by Virinchi Balabhadrapatruni on 7/8/13.
//  Copyright (c) 2013 ECG. All rights reserved.
//

#import "ViewController.h"

#define DEV_VIS_URL @"http://isensedev.cs.uml.edu/highvis.php?sessions="
#define PROD_VIS_URL @"http://isenseproject.org/highvis.php?sessions="

#define DEV_DEFAULT_EXP 596
#define PROD_DEFAULT_EXP 409

@interface ViewController ()

- (IBAction)showMenu:(id)sender;

@end

@implementation ViewController

@synthesize start, menuButton, vector_status, login_status, items, recordLength, countdown, change_name, iapi, running, timeOver, setupDone, dfm, motionmanager, locationManager, recordDataTimer, timer, testLength, expNum, sampleInterval, sessionName,geoCoder,city,country,address,dataToBeJSONed,elapsedTime,recordingRate, experiment,firstName,lastInitial,userName,useDev,passWord,session_num,managedObjectContext,dataSaver ;

- (void)viewDidLoad {
    
    [super viewDidLoad];
	UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [start addGestureRecognizer:longPress];
    
    recordLength = 10;
    countdown = 10;
    
    useDev = TRUE;
    
    self.navigationItem.rightBarButtonItem = menuButton;
    iapi = [iSENSE getInstance];
    [iapi toggleUseDev: useDev];
    
    
    running = NO;
    timeOver = NO;
    setupDone = NO;
    
    if (useDev) {
        expNum = DEV_DEFAULT_EXP;
    } else {
        expNum = PROD_DEFAULT_EXP;
    }
    
    dfm = [[DataFieldManager alloc] init];
    //[dfm setEnabledField:YES atIndex:fACCEL_Y];
    motionmanager = [[CMMotionManager alloc] init];
    
    userName = @"sor";
    passWord = @"sor";
    firstName = @"No Name";
    lastInitial = @"Provided";
    [self login:@"sor" withPassword:@"sor"];
    
    // Managed Object Context for Data_CollectorAppDelegate
    if (managedObjectContext == nil) {
        managedObjectContext = [(AppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
    }
    
    // DataSaver from Data_CollectorAppDelegate
    if (dataSaver == nil) {
        dataSaver = [(AppDelegate *) [[UIApplication sharedApplication] delegate] dataSaver];
    }

    
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.isMovingToParentViewController == YES) {
        change_name = [[CODialog alloc] initWithWindow:self.view.window];
        change_name.title = @"Enter First Name and Last Initial";
        [change_name addTextFieldWithPlaceholder:@"First Name" secure:NO];
        [change_name addTextFieldWithPlaceholder:@"Last Initial" secure:NO];
        UITextField *last = [change_name textFieldAtIndex:1];
        [last setDelegate:self];
        [change_name addButtonWithTitle:@"Done" target:self selector:@selector(changeName)];
        [change_name showOrUpdateAnimated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)longPress:(UILongPressGestureRecognizer*)gesture {
    if ( gesture.state == UIGestureRecognizerStateEnded ) {
        NSLog(@"Long Press");
        if (!running) {
            // Get Field Order
            [dfm getFieldOrderOfExperiment:expNum];
            [self getEnabledFields];
            // Record Data
            running = YES;
            [start setEnabled:NO];
            [self recordData];
        }
        
        
        
    }
}

// Record the data and return the NSMutable array to be JSONed
- (void) recordData {
    
    // Get the recording rate
    float rate = .125;
    /*NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
     NSString *sampleIntervalString = [prefs valueForKey:[StringGrabber grabString:@"key_sample_interval"]];
     sampleInterval = [sampleIntervalString floatValue];*/
    sampleInterval = 125;
    if (sampleInterval > 0) rate = sampleInterval / 1000;
    
    elapsedTime = 0;
    recordingRate = rate * 1000;
    
    NSLog(@"rate: %d", recordingRate);
    
    // Set the accelerometer update interval to reccomended sample interval, and start updates
    motionmanager.accelerometerUpdateInterval = rate;
    motionmanager.magnetometerUpdateInterval = rate;
    motionmanager.gyroUpdateInterval = rate;
    if (motionmanager.accelerometerAvailable) [motionmanager startAccelerometerUpdates];
    if (motionmanager.magnetometerAvailable) [motionmanager startMagnetometerUpdates];
    if (motionmanager.gyroAvailable) [motionmanager startGyroUpdates];
    
    // New JSON array to hold data
    dataToBeJSONed = [[NSMutableArray alloc] init];
    
    // Start the new timers TODO - put them on dispatch?
    recordDataTimer = [NSTimer scheduledTimerWithTimeInterval:rate target:self selector:@selector(buildRowOfData) userInfo:nil repeats:YES];
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(updateElapsedTime) userInfo:nil repeats:YES];
}


- (void) updateElapsedTime {
    
    if (!running) {
        
    }
    
    
    
    dispatch_queue_t queue = dispatch_queue_create("automatic_update_elapsed_time", NULL);
    dispatch_async(queue, ^{
        elapsedTime += 1;
        
        int seconds = elapsedTime % 60;
        
        NSString *secondsStr;
        if (seconds < 10)
            secondsStr = [NSString stringWithFormat:@"0%d", seconds];
        else
            secondsStr = [NSString stringWithFormat:@"%d", seconds];
        
        int dataPoints = (1000 / recordingRate) * elapsedTime;
        
        NSLog(@"points: %d", dataPoints);
        
        if (countdown >= -1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [start setTitle:[NSString stringWithFormat:@"%d", countdown] forState:UIControlStateNormal];
                countdown--;
            });
        }
        
        if (countdown < -1) {
            
            [self stopRecording:motionmanager];
        }
        
        
        
        
    });
    
}


// Fill dataToBeJSONed with a row of data
- (void) buildRowOfData {
    Fields *fieldsRow = [[Fields alloc] init];
    
    // Fill a new row of data starting with time
    double time = [[NSDate date] timeIntervalSince1970];
    if ([dfm enabledFieldAtIndex:fTIME_MILLIS])
        fieldsRow.time_millis = [[NSNumber alloc] initWithDouble:time * 1000];
    NSLog(@"Current time is: %@.", fieldsRow.time_millis);
    
    
    dispatch_queue_t queue = dispatch_queue_create("record_data", NULL);
    dispatch_async(queue, ^{
        // acceleration in meters per second squared
        if ([dfm enabledFieldAtIndex:fACCEL_X]) {
            fieldsRow.accel_x = [[NSNumber alloc] initWithDouble:[motionmanager.accelerometerData acceleration].x * 9.80665];
            NSLog(@"Current accel x is: %@.", fieldsRow.accel_x);
            dispatch_async(dispatch_get_main_queue(), ^{
                vector_status.text = [@"X: " stringByAppendingString:[fieldsRow.accel_x stringValue]];
            });
        }
        
        if ([dfm enabledFieldAtIndex:fACCEL_Y]) {
            fieldsRow.accel_y = [[NSNumber alloc] initWithDouble:[motionmanager.accelerometerData acceleration].y * 9.80665];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([dfm enabledFieldAtIndex:fACCEL_X])
                    vector_status.text = [vector_status.text stringByAppendingString:[@", Y: " stringByAppendingString:[fieldsRow.accel_y stringValue]]];
                else
                    vector_status.text = [@"Y: " stringByAppendingString:[fieldsRow.accel_y stringValue]];
            });
            NSLog(@"Current accel y is: %@.", fieldsRow.accel_y);
        }
        if ([dfm enabledFieldAtIndex:fACCEL_Z]) {
            fieldsRow.accel_z = [[NSNumber alloc] initWithDouble:[motionmanager.accelerometerData acceleration].z * 9.80665];
            NSLog(@"Current accel z is: %@.", fieldsRow.accel_z);
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([dfm enabledFieldAtIndex:fACCEL_X] || [dfm enabledFieldAtIndex:fACCEL_Y]) {
                    vector_status.text = [vector_status.text stringByAppendingString:[@", Z: " stringByAppendingString:[fieldsRow.accel_z stringValue]]];
                } else
                    vector_status.text = [@"Z: " stringByAppendingString:[fieldsRow.accel_z stringValue]];
            });
            
            if ([dfm enabledFieldAtIndex:fACCEL_TOTAL]) {
                fieldsRow.accel_total = [[NSNumber alloc] initWithDouble:
                                         sqrt(pow(fieldsRow.accel_x.doubleValue, 2)
                                              + pow(fieldsRow.accel_y.doubleValue, 2)
                                              + pow(fieldsRow.accel_z.doubleValue, 2))];
                NSLog(@"Current accel total is: %@.", fieldsRow.accel_total);
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([dfm enabledFieldAtIndex:fACCEL_X] || [dfm enabledFieldAtIndex:fACCEL_Y] || [dfm enabledFieldAtIndex:fACCEL_Z])
                        vector_status.text = [vector_status.text stringByAppendingString:[@", Magnitude: " stringByAppendingString:[fieldsRow.accel_total stringValue]]];
                    else
                        vector_status.text = [@"Magnitude: " stringByAppendingString:[fieldsRow.accel_total stringValue]];
                });
            }
        }
    });
    // Update parent JSON object
    [dfm orderDataFromFields:fieldsRow];
    
    if (dfm.data != nil && dataToBeJSONed != nil)
        [dataToBeJSONed addObject:dfm.data];
    else {
        NSLog(@"something is wrong");
    }
}

// This inits locations
- (void) initLocations {
    if (!locationManager) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLDistanceFilterNone;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation];
        geoCoder = [[CLGeocoder alloc] init];
    }
}

// Stops the recording and returns the actual data recorded :)
-(void) stopRecording:(CMMotionManager *)finalMotionManager {
    
    // Stop Timers
    [timer invalidate];
    [recordDataTimer invalidate];
    
    // Stop Sensors
    if (finalMotionManager.accelerometerActive) [finalMotionManager stopAccelerometerUpdates];
    if (finalMotionManager.gyroActive) [finalMotionManager stopGyroUpdates];
    if (finalMotionManager.magnetometerActive) [finalMotionManager stopMagnetometerUpdates];
    
    // Stop Recording
    running = NO;
    [vector_status setText:@"Y: "];
    countdown = recordLength;
    dispatch_async(dispatch_get_main_queue(), ^{
        [start setTitle:@"Hold to Start" forState:UIControlStateNormal];
        [start setEnabled:YES];
        
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Publish to iSENSE?"
                                                          message:nil
                                                         delegate:self
                                                cancelButtonTitle:@"Discard"
                                                otherButtonTitles:@"Publish", nil];
        
        message.delegate = self;
        [message show];
    });
    
}

// Enabled fields check
- (void) getEnabledFields {
    
    // if exp# = -1 then enable all, else enable some
    if (expNum == -1) {
        
        for (int i = 0; i < [[dfm order] count]; i++) {
            [dfm setEnabledField:YES atIndex:i];
        }
        
    } else {
        
        int i = 0;
        
        for (NSString *s in [dfm order]) {
            if ([s isEqualToString:[StringGrabber grabField:@"accel_x"]]) {
                [dfm setEnabledField:YES atIndex:fACCEL_X];
                
            }
            else if ([s isEqualToString:[StringGrabber grabField:@"accel_y"]]) {
                [dfm setEnabledField:YES atIndex:fACCEL_Y];
            }
            else if ([s isEqualToString:[StringGrabber grabField:@"accel_z"]]) {
                [dfm setEnabledField:YES atIndex:fACCEL_Z];
            }
            else if ([s isEqualToString:[StringGrabber grabField:@"accel_total"]]) {
                [dfm setEnabledField:YES atIndex:fACCEL_TOTAL];
            }
            else if ([s isEqualToString:[StringGrabber grabField:@"time"]]) {
                [dfm setEnabledField:YES atIndex:fTIME_MILLIS];
            }
            
            ++i;
        }
    }
}

- (void) browseExp {
    [experiment hideAnimated:YES];
    ExperimentBrowseViewController *browse;
    browse = [[ExperimentBrowseViewController alloc] init];
    browse.title = @"Browse for Experiments";
    browse.chosenExperiment = &expNum;
    [self.navigationController pushViewController:browse animated:YES];
    
}

- (void) QRCode {
    //The following feature is experimental;
    [experiment hideAnimated:YES];
    if ([[UIApplication sharedApplication]
         canOpenURL:[NSURL URLWithString:@"pic2shop:"]]) {
        NSURL *urlp2s = [NSURL URLWithString:@"pic2shop://scan?callback=carPhysics%3A//EAN"];
        [[UIApplication sharedApplication] openURL:urlp2s];
    } else {
        NSURL *urlapp = [NSURL URLWithString:
                         @"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewSoftware?id=308740640&mt=8"];
        [[UIApplication sharedApplication] openURL:urlapp];
    }
}

- (void) expCode {
    [experiment hideAnimated:YES];
    expNum = [[experiment textForTextFieldAtIndex:0] intValue];
    NSLog(@"experiment number: %d", expNum);
}

// Save a data set so you don't have to upload it immediately
- (void) saveDataSetWithDescription:(NSString *)description {
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    expNum = [[prefs stringForKey:[StringGrabber grabString:@"key_exp_automatic"]] intValue];
    
    bool uploadable = false;
    if (expNum > 1) uploadable = true;
    
    DataSet *ds = [NSEntityDescription insertNewObjectForEntityForName:@"DataSet" inManagedObjectContext:managedObjectContext];
    [ds setName:sessionName];
    [ds setDataDescription:description];
    [ds setEid:[NSNumber numberWithInt:expNum]];
    [ds setData:dataToBeJSONed];
    [ds setPicturePaths:[NSNull null]];
    [ds setSid:[NSNumber numberWithInt:-1]];
    [ds setCity:city];
    [ds setCountry:country];
    [ds setAddress:address];
    [ds setUploadable:[NSNumber numberWithBool:uploadable]];
    
    // Add the new data set to the queue
    [dataSaver addDataSet:ds];
    NSLog(@"There are %d dataSets in the dataSaver.", dataSaver.count);
    
    // Commit the changes
    NSError *error = nil;
    if (![managedObjectContext save:&error]) {
        // Handle the error.
        NSLog(@"%@", error);
    }
    
}

- (bool) uploadData:(NSString *) description {
    
    if (![iapi isLoggedIn]) {
        [self.view makeWaffle:@"Not logged in" duration:WAFFLE_LENGTH_SHORT position:WAFFLE_BOTTOM image:WAFFLE_RED_X];
        return false;
        
    }
    
    NSString *name = firstName;
    name = [name stringByAppendingString:@" "];
    name = [name stringByAppendingString:lastInitial];
    
    session_num = [iapi createSession:name withDescription:description Street:address City:city Country:country toExperiment:[NSNumber numberWithInt: expNum]];
    
    
    NSArray *array = [NSArray arrayWithArray:dataToBeJSONed];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
    if (error != nil) {
        NSLog(@"Error:%@", error);
        return false;
    }
    /*
    bool success = [iapi putSessionData:jsonData forSession:session_num inExperiment:[NSNumber numberWithInt: expNum]];
    if (!success)
        [self.view makeWaffle:@"Unable to upload" duration:WAFFLE_LENGTH_SHORT position:WAFFLE_BOTTOM title:nil image:WAFFLE_RED_X];
    else {
        [self.view makeWaffle:@"Upload successful" duration:WAFFLE_LENGTH_SHORT position:WAFFLE_BOTTOM title:nil image:WAFFLE_CHECKMARK];
        
    }*/
    [self saveDataSetWithDescription:@"Car Ramp Physics"];
    return true;
    
}

- (IBAction)showMenu:(id)sender {
    
    
    RNGridMenu *menu;
    
    UIImage *upload = [UIImage imageNamed:@"upload2"];
    UIImage *settings = [UIImage imageNamed:@"settings"];
    UIImage *code = [UIImage imageNamed:@"barcode"];
    UIImage *login = [UIImage imageNamed:@"users"];
    UIImage *about = [UIImage imageNamed:@"info"];
    UIImage *reset = [UIImage imageNamed:@"reset"];
    
    void (^uploadBlock)() = ^() {
        NSLog(@"Upload button pressed");
        UploadTableViewController *uploadController;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            uploadController = [[UploadTableViewController alloc] initWithNibName:@"UploadTableViewController_iPhone" bundle:nil];
        } else {
           uploadController = [[UploadTableViewController alloc] initWithNibName:@"UploadTableViewController_iPad" bundle:nil];
        }    

        uploadController.saver = dataSaver;
        [self.navigationController pushViewController:uploadController animated:YES];
    };
    void (^settingsBlock)() = ^() {
        NSLog(@"Record Settings button pressed");
        UIActionSheet *settings_menu = [[UIActionSheet alloc] initWithTitle:@"Settings" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Variables", @"Length", @"Name", nil];
        [settings_menu showInView:self.view];
        
    };
    void (^codeBlock)() = ^() {
        NSLog(@"Experiment button pressed");
        experiment = [[CODialog alloc] initWithWindow:self.view.window];
        [experiment addTextFieldWithPlaceholder:@"Enter Experiment #" secure:NO];
        [experiment addButtonWithTitle:@"Browse" target:self selector:@selector(browseExp)];
        [experiment addButtonWithTitle:@"QR Code" target:self selector:@selector(QRCode)];
        [experiment addButtonWithTitle:@"Done" target:self selector:@selector(expCode)];
        [experiment showOrUpdateAnimated:YES];
        
    };
    void (^loginBlock)() = ^() {
        NSLog(@"Login button pressed");
        
        UIAlertView *loginalert = [[UIAlertView alloc] initWithTitle:@"Login to iSENSE" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [loginalert setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
        [loginalert show];
    };
    void (^aboutBlock)() = ^() {
        NSLog(@"About button pressed");
        
        AboutViewController *about;
        // Override point for customization after application launch.
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            about = [[AboutViewController alloc] initWithNibName:@"AboutViewController_iPhone" bundle:nil];
        } else {
            about = [[AboutViewController alloc] initWithNibName:@"AboutViewController_iPad" bundle:nil];
        }
        
        [self.navigationController pushViewController:about animated:YES];
        
    };
    void (^resetBlock)() = ^() {
        NSLog(@"Reset button pressed");
        countdown = recordLength = 10;
        userName = passWord = @"sor";
        [self login:userName withPassword:passWord];
        login_status.text = [@"Logged in as: " stringByAppendingString: userName];
        login_status.text = [login_status.text stringByAppendingString:@" Name: "];
        login_status.text = [login_status.text stringByAppendingString:firstName];
        login_status.text = [login_status.text stringByAppendingString:@" "];
        login_status.text = [login_status.text stringByAppendingString:lastInitial];
    };
    
    RNGridMenuItem *uploadItem = [[RNGridMenuItem alloc] initWithImage:upload title:@"Upload" action:uploadBlock];
    RNGridMenuItem *recordSettingsItem = [[RNGridMenuItem alloc] initWithImage:settings title:@"Settings" action:settingsBlock];
    RNGridMenuItem *codeItem = [[RNGridMenuItem alloc] initWithImage:code title:@"Experiment" action:codeBlock];
    RNGridMenuItem *loginItem = [[RNGridMenuItem alloc] initWithImage:login title:@"Login" action:loginBlock];
    RNGridMenuItem *aboutItem = [[RNGridMenuItem alloc] initWithImage:about title:@"About" action:aboutBlock];
    RNGridMenuItem *resetItem = [[RNGridMenuItem alloc] initWithImage:reset title:@"Reset" action:resetBlock];
    
    items = [[NSArray alloc] initWithObjects:uploadItem, recordSettingsItem, codeItem, loginItem, aboutItem, resetItem, nil];
    
    menu = [[RNGridMenu alloc] initWithItems:items];
    
    menu.delegate = self;
    
    [menu showInViewController:self center:CGPointMake(self.view.bounds.size.width/2.f, self.view.bounds.size.height/2.f)];
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0){
        
    } else if (buttonIndex == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter recording length" message:@"Enter time in seconds." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Done", nil];
        [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alert show];
    } else if (buttonIndex == 2){
        change_name = [[CODialog alloc] initWithWindow:self.view.window];
        change_name.title = @"Enter First Name and Last Initial";
        [change_name addTextFieldWithPlaceholder:@"First Name" secure:NO];
        [change_name addTextFieldWithPlaceholder:@"Last Initial" secure:NO];
        UITextField *last = [change_name textFieldAtIndex:1];
        [last setDelegate:self];
        [change_name addButtonWithTitle:@"Done" target:self selector:@selector(changeName)];
        [change_name showOrUpdateAnimated:YES];
    }
    
    
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    return (newLength > 1) ? NO : YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([alertView.title isEqualToString:@"Enter recording length"]) {
        
        if([title isEqualToString:@"Done"])
        {
            UITextField *length = [alertView textFieldAtIndex:0];
            NSCharacterSet *_NumericOnly = [NSCharacterSet decimalDigitCharacterSet];
            NSCharacterSet *myStringSet = [NSCharacterSet characterSetWithCharactersInString:length.text];
            
            if ([_NumericOnly isSupersetOfSet: myStringSet])
            {
                recordLength = countdown = [length.text intValue];
                NSLog(@"Length is %d", recordLength);
                
            } else {
                [self.view makeWaffle:@"Invalid Length"
                             duration:WAFFLE_LENGTH_SHORT
                             position:WAFFLE_BOTTOM
                                image:WAFFLE_RED_X];
            }
        }
    } else if ([alertView.title isEqualToString:@"Login to iSENSE"]) {
        [self login:[alertView textFieldAtIndex:0].text withPassword:[alertView textFieldAtIndex:1].text];
        [login_status setText:[@"Logged in as: " stringByAppendingString: [alertView textFieldAtIndex:0].text]];
    } else if ([alertView.title isEqualToString:@"Publish to iSENSE?"]) {
        if ([title isEqualToString:@"Discard"]) {
            [self.view makeWaffle:@"Data discarded!" duration:WAFFLE_LENGTH_SHORT position:WAFFLE_BOTTOM title:nil image:WAFFLE_RED_X];
        } else {
            [self getDispatchDialogWithMessage:@"Uploading to iSENSE..."];
            [self uploadData: @"Car Ramp Physics Test"];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"View data on iSENSE?" message:nil delegate:self cancelButtonTitle:@"Don't View" otherButtonTitles:@"View", nil];
            [alert show];
        }
    } else if ([alertView.title isEqualToString:@"View data on iSENSE?"]) {
        
        if ([title isEqualToString:@"View"]) {
            NSString *url;
            NSLog(@"%@",session_num);
            NSLog(@"\n%@", [NSString stringWithFormat:@"%d", [session_num intValue]]);
            if (useDev) {
                url = [DEV_VIS_URL stringByAppendingString:[NSString stringWithFormat:@"%d", [session_num intValue]]];
            } else {
                url = [PROD_VIS_URL stringByAppendingString:[NSString stringWithFormat:@"%d", [session_num intValue]]];
            }
            NSLog(@"%@",url);
            UIApplication *mySafari = [UIApplication sharedApplication];
            NSURL *myURL = [[NSURL alloc]initWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            [mySafari openURL:myURL];
        }
        
    }
}

- (void) changeName {
    
    [change_name hideAnimated:YES];
    firstName = [change_name textForTextFieldAtIndex:0];
    lastInitial = [change_name textForTextFieldAtIndex:1];
    login_status.text = [@"Logged in as: " stringByAppendingString: userName];
    login_status.text = [login_status.text stringByAppendingString:@" Name: "];
    login_status.text = [login_status.text stringByAppendingString:firstName];
    login_status.text = [login_status.text stringByAppendingString:@" "];
    login_status.text = [login_status.text stringByAppendingString:lastInitial];
    
}

- (void) login:(NSString *)usernameInput withPassword:(NSString *)passwordInput {
    
    CODialog *message = [self getDispatchDialogWithMessage:@"Logging in..."];
    [message showOrUpdateAnimated:YES];
    NSLog(@"Making waffle");
    dispatch_queue_t queue = dispatch_queue_create("automatic_login_from_login_function", NULL);
    dispatch_async(queue, ^{
        BOOL success = [iapi login:usernameInput with:passwordInput];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self.view makeWaffle:@"Login Successful!"
                             duration:WAFFLE_LENGTH_SHORT
                             position:WAFFLE_BOTTOM
                                image:WAFFLE_CHECKMARK];
                login_status.text = [@"Logged in as: " stringByAppendingString: usernameInput];
                login_status.text = [login_status.text stringByAppendingString:@" Name: "];
                login_status.text = [login_status.text stringByAppendingString:firstName];
                login_status.text = [login_status.text stringByAppendingString:@" "];
                login_status.text = [login_status.text stringByAppendingString:lastInitial];
                userName = usernameInput;
                passWord = passwordInput;
            } else {
                [self.view makeWaffle:@"Login Failed!"
                             duration:WAFFLE_LENGTH_SHORT
                             position:WAFFLE_BOTTOM
                                image:WAFFLE_RED_X];
            }
            [message hideAnimated:YES];
        });
    });
    
}

- (CODialog *) getDispatchDialogWithMessage:(NSString *)dString {
    CODialog *spinner = [[CODialog alloc] initWithWindow:self.view.window];
    [spinner setTitle:dString];
    spinner.dialogStyle = CODialogStyleIndeterminate;
    return spinner;
}





@end