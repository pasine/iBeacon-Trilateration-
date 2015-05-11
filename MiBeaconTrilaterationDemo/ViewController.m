/*
 Copyright (c) 2015 Farrukh Jadoon
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

#import "ViewController.h"
@import QuartzCore;

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    locationManager = [[CLLocationManager alloc] init];
    [locationManager setDelegate:self];
    
    // Location patch for iOS8
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) [locationManager requestAlwaysAuthorization];
    
    // Estimote beacon UUID
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
    beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid identifier:@"se.mathijs.MiBeaconTrilateration"];
    
    // start ranging ID
    [locationManager startRangingBeaconsInRegion:beaconRegion];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *plistPath = [bundle pathForResource:@"beaconCoordinates" ofType:@"plist"];
    NSDictionary *coordinates = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    
    MiBeaconTrilaterator = [[MiBeaconTrilateration alloc] initWitBeacons:coordinates];
    
    // misc UI settings
    [beaconGrid.layer setCornerRadius:10];
    [selfView.layer setCornerRadius:10];
    
    [self plotBeaconsFromPlistToGrid];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)plotBeaconsFromPlistToGrid {
    // load plist to dictionary
    if (!beaconCoordinates)
    {
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *plistPath = [bundle pathForResource:@"beaconCoordinates" ofType:@"plist"];
        beaconCoordinates = [[NSDictionary alloc] initWithContentsOfFile:plistPath];

        // the plist file can be easily moved to a remote location
//        NSURL *plistURL = [NSURL URLWithString:@"http://example.com/beaconCoordinates.plist"];
//        beaconCoordinates = [[NSDictionary alloc] initWithContentsOfURL:plistURL];
        
    }
    
    // determine max coordinate to calculate scalefactor
    float maxCoordinate = -MAXFLOAT;
    float minCoordinate = MAXFLOAT;
    
    for (NSString* key in beaconCoordinates) {
        NSArray *coordinates = [beaconCoordinates objectForKey:key];
        int X = [[coordinates objectAtIndex:0] intValue];
        int Y = [[coordinates objectAtIndex:1] intValue];
        
        // max & min y & x
        if (X < minCoordinate) minCoordinate = X;
        if (X > maxCoordinate) maxCoordinate = X;
        if (Y < minCoordinate) minCoordinate = Y;
        if (Y > maxCoordinate) maxCoordinate = Y;
    }
    
    scaleFactor = 290 / (maxCoordinate-minCoordinate); //290 is width/height gridView
    maxY = (maxCoordinate-minCoordinate) * scaleFactor;
    
    // loop through dictionary to plot all beacons
    for (NSString* key in beaconCoordinates) {
        NSArray *coordinates = [beaconCoordinates objectForKey:key];
        int X = [[coordinates objectAtIndex:0] intValue];
        int Y = [[coordinates objectAtIndex:1] intValue];
        
        UILabel *beaconLabel = [[UILabel alloc] initWithFrame:CGRectMake((X * scaleFactor)-10, (maxY-(Y * scaleFactor))-10, 20, 20)];
        [beaconLabel setText:key];
        
        [beaconLabel setBackgroundColor:[UIColor colorWithRed:(10/255.0) green:(140/255.0) blue:(220/255.0) alpha:1]];
        [beaconLabel setTextAlignment:NSTextAlignmentCenter];
        [beaconLabel setFont:[UIFont fontWithName:@"Helvetica-Neue Light" size:10.0f]];
        [beaconLabel setTextColor:[UIColor whiteColor]];
        [beaconLabel.layer setCornerRadius:10.0f];
        
        [beaconGrid addSubview:beaconLabel];
    }
}

- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    foundBeacons = [beacons copy];
    
    // put them in the tableView
    [beaconsFound setText:[NSString stringWithFormat:@"Beacons found (%lu)", (unsigned long)[foundBeacons count]]];
    [beaconsTableView reloadData];
    
    // perform trilateration
    [MiBeaconTrilaterator trilaterateWithBeacons:foundBeacons done:^(NSString *error, NSArray *coordinates) {
        if ([error isEqualToString:@""])
        {
            float x = [[coordinates objectAtIndex:0] floatValue];
            float y = [[coordinates objectAtIndex:1] floatValue];
            
            [xyResult setText:[NSString stringWithFormat:@"X: %.1f   Y: %.1f", x, y]];
            [selfView setHidden:NO];
            [selfView setFrame:CGRectMake((x * scaleFactor)-10, (maxY-(y * scaleFactor))-10, 20, 20)];
        }
        else
        {
            NSLog(@"%@", error);
            [xyResult setText:@"Sorry, unable to trilaterate"];
            [selfView setHidden:YES];
        }
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [foundBeacons count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CLBeacon *currentBeacon = [foundBeacons objectAtIndex:indexPath.row];
    UITableViewCell *cell;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        [cell.textLabel setTextColor:[UIColor darkGrayColor]];
        [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica-Neue Thin" size:15.0f]];
        [cell.textLabel setTextAlignment:NSTextAlignmentCenter];
    }
    
    [cell.textLabel setText:[NSString stringWithFormat:@"%d/%d RSSI:%ld distance: %.1fm", [[currentBeacon major] intValue], [[currentBeacon minor] intValue],(long)[currentBeacon rssi], [currentBeacon accuracy]]];
    
    return cell;
}

@end
