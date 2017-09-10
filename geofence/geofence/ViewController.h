//
//  ViewController.h
//  geofence
//
//  Created by Treinamento on 26/08/17.
//  Copyright © 2017 dauster. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController <CLLocationManagerDelegate,MKMapViewDelegate>

@property (weak,nonatomic) IBOutlet MKMapView *mapView;

@end

