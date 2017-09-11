//
//  ViewController.m
//  geofence
//
//  Created by Treinamento on 26/08/17.
//  Copyright © 2017 dauster. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

// 1 . Create location Manager e o Map View
@property (strong,nonatomic) CLLocationManager *locationManager;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Verifica se o serviço de localização está disponivel
    if(![CLLocationManager locationServicesEnabled]) {
        [self alertWithTitle:@"Aviso" andMessage:@"Serviço de localização não disponivel"];
        return;
    }
    
    // 2.Configura o locationManager
    if (nil == self.locationManager){
        self.locationManager = [[CLLocationManager alloc] init];        // inicia o objeto locationManager.
        self.locationManager.delegate = self;                           // seta  o delegate do locationManager.
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest; // Use o mais alto nível de precisão.
        self.locationManager.distanceFilter = kCLDistanceFilterNone;    // Indicando que todos os movimentos devem ser relatados.
    }
    
    // 3.Configura o MapView
    
    self.mapView.delegate = self; // seta  o delegate do mapView caso não tenha setado pelo storyboard.
    self.mapView.showsUserLocation = YES; // Um valor booleano que indica se o mapa deve tentar exibir a localização do usuário.
    self.mapView.userTrackingMode = MKUserTrackingModeFollow; // O modo utilizado para rastrear a localização do usuário. (O mapa segue a localização do usuário.)
    
    // 4. Configura geofence
    [self setupData:[self buildGeofenceData]];
    
}


- (void)viewDidAppear:(BOOL)animated{
    
    
    switch ([CLLocationManager authorizationStatus]) {
        
        // 1. status não determinado
        case kCLAuthorizationStatusNotDetermined:
            
            if([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]){
                [self.locationManager requestAlwaysAuthorization];
            }
            
            break;
            
        // 2. autorização negada pelo usuário
        case kCLAuthorizationStatusDenied:
            [self alertWithTitle:@"Aviso" andMessage:@"Os serviços de localização foram previamente negados. Ative os serviços de localização para este aplicativo em Configurações."];
            break;
            
        // 3. se já tiver autorização
        default:
            [self.locationManager startUpdatingLocation];
            break;
    }
    
}



-(void) setupData:(NSArray *)geofences{
    
    // 1. verifica se o sistema pode rastrear regiões
    if([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]){
        
        //inicia o monitoramento das regiões
        for(CLCircularRegion *geofence in geofences) {
            
            geofence.notifyOnEntry = YES;
            geofence.notifyOnExit  = YES;
            
            //2. cria regiões baseada no arquivo plist
            [self.locationManager startMonitoringForRegion:geofence];
    
            
            //4. cria uma annotation com informação do local
            MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
            annotation.coordinate = geofence.center;
            annotation.title = geofence.identifier;
            
            [self.mapView addAnnotation:annotation];
            
            
            //3. cria um circulo para demarca a região que esta sendo monitorada
            MKCircle *circle = [MKCircle circleWithCenterCoordinate:geofence.center radius:geofence.radius];
            circle.title     = geofence.description;
            [self.mapView addOverlay:circle];
            
        }
        
    
        CLCircularRegion *region = geofences[0];
        
        MKCoordinateRegion theRegion;
        theRegion.center.latitude  = region.center.latitude;
        theRegion.center.longitude = region.center.longitude;
        
        // Zoom out
        theRegion.span.longitudeDelta = 0.005;
        theRegion.span.latitudeDelta  = 0.005;
        
        [self.mapView setRegion:theRegion animated:YES];
        
    }
    else {
        
        [self alertWithTitle:@"Aviso" andMessage:@"O sistema não pode rastrear regiões"];

    }
    
}


// Retorna um array de regiões para monitoramento
- (NSArray*)buildGeofenceData
{
    NSString *plistPath   = [[NSBundle mainBundle] pathForResource:@"regions" ofType:@"plist"];
    NSArray  *regionArray = [NSArray arrayWithContentsOfFile:plistPath];
    
    NSMutableArray *geofences = [NSMutableArray array];
    
    for(NSDictionary *regionDict in regionArray) {
        CLCircularRegion *region = [self mapDictionaryToRegion:regionDict];
        [geofences addObject:region];
    }
    
    return [NSArray arrayWithArray:geofences];
}


// converte os dados da plist em Regiões
- (CLCircularRegion*)mapDictionaryToRegion:(NSDictionary*)dictionary
{
    NSString *title = [dictionary valueForKey:@"description"];
    
    CLLocationDegrees latitude = [[dictionary valueForKey:@"latitude"] doubleValue];
    CLLocationDegrees longitude =[[dictionary valueForKey:@"longitude"] doubleValue];
    CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    CLLocationDistance regionRadius = [[dictionary valueForKey:@"radius"] doubleValue];
    
    return  [[CLCircularRegion alloc] initWithCenter:centerCoordinate
                                              radius:regionRadius
                                          identifier:title];
    
}



- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay{
    
    if ([overlay isKindOfClass:[MKCircle class]])
    {
        MKCircleRenderer *aRenderer = [[MKCircleRenderer alloc] initWithCircle:(MKCircle*)overlay];
        
        aRenderer.fillColor = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        aRenderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        aRenderer.lineWidth = 3;
        
        return aRenderer;
    }
    
    return nil;
}

// função que ira ser chamada quando eu entrar na regiões monitoradas
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    NSLog(@"entrou %@",region.identifier);
}

// função que ira ser chamada quando eu sair das regiões monitoradas
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    NSLog(@"saiu %@",region.identifier);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error{
    NSLog(@"error %@",region.identifier);
}




-(void) alertWithTitle:(NSString*) title andMessage:(NSString *) message{
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];

}


@end
