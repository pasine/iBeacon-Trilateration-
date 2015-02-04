Shennekt iBeacon Trilateration Demo
===================================

Built by Farrukh Jadoon
Release date (v1.0): Feb 3, 2015

>Patched for iOS 8 Core Location compatibility
>Fixed the corrupted Demo test files
>Added the info.plist parameter for NSLocationAlwaysUsageDescription for iOS 8 Location support. 




Instructions:

Set the iBeacons minor ID as the keys (at least 3) and planar coordinates (X, Y) in the beaconCoordinates.plist file. Beacons are identified by the minor ID's and are trilaterated as:

    [MiBeaconTrilaterator trilaterateWithBeacons:foundBeacons done:^(NSString *error, NSArray *coordinates) {
        if ([error isEqualToString:@""])
        {
            float x = [[coordinates objectAtIndex:0] floatValue];
            float y = [[coordinates objectAtIndex:1] floatValue];
        }
        else
        {
            NSLog(@"%@", error);
        }
    }];


Credits:

Mathijs Vreeman
Wojciech Borowicz