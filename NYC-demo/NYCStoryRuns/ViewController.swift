import UIKit
import MapKit
import CoreLocation
import AVFoundation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var monitoredRegions: Dictionary<String, Date> = [:]
    var myLocations: [CLLocation] = []
    
    var mAudioPlayer: AVAudioPlayer?
    var mAudioSession : AVAudioSession?
    var mDebugFile : FileHandle?
    
    var mStopButton: UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup locationManager
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        // setup mapView
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // setup AVFoundation
        mAudioSession = AVAudioSession.sharedInstance()
        do{
            try mAudioSession?.setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.duckOthers)
        }
        catch{}
        
        mStopButton = UIButton(type: UIButtonType.system) as UIButton
        mStopButton?.frame = CGRect(x: 170, y: 600, width: 48, height: 48)
        mStopButton?.addTarget(self, action:#selector(handleButton), for: .touchUpInside)
        self.view.addSubview(mStopButton!)
        
        
        // setup test data
        setupData()
    }
    
    func handleButton(sender:UIButton!) {
        mAudioPlayer?.stop()
        mStopButton?.setImage(nil, for: .normal)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // status is not determined
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
            // authorization were denied
        else if CLLocationManager.authorizationStatus() == .denied {
            showAlert("Location services were previously denied. Please enable location services for this app in Settings.")
        }
            // we do have authorization
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func setupData() {
        // check if can monitor regions
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            addGeoAnnotation("Belvedere Castle- Lee Goldberg"   , radius: 150.0, latitude: 40.7793978, longitude: -73.9691654)
            addGeoAnnotation("Harlem Meer- S. Epatha Merkerson" , radius: 200.0, latitude: 40.7965525, longitude: -73.9521687)
            addGeoAnnotation("Ladies’ Pavilion- Téa Leoni"      , radius: 225.0, latitude: 40.7777629, longitude: -73.9733762)
            addGeoAnnotation("Loeb Boathouse- Meredith Vieira"  , radius: 225.0, latitude: 40.7752463, longitude: -73.9688693)
            
            addGeoAnnotation("Obelisk- Thomas P. Campbell"      , radius: 225.0, latitude: 40.779641, longitude: -73.965408)
            addGeoAnnotation("Shakespeare Garden- Marcia Gay Harden", radius: 225.0, latitude: 40.779824, longitude: -73.969887)
            addGeoAnnotation("Tennis Courts- John McEnroe"      , radius: 225.0, latitude: 40.7894223, longitude: -73.9620745)
            addGeoAnnotation("The Pond- Sarah Jessica Parker"   , radius: 225.0, latitude: 40.7658417, longitude: -73.9743847)
            
            addGeoAnnotation("Work-Subway Station"              , radius: 225.0, latitude: 40.743862, longitude: -73.992087)
            addGeoAnnotation("Work- Oppo Direction"             , radius: 225.0, latitude: 40.738696, longitude: -73.995869)
            addGeoAnnotation("Upper East Side"                  , radius: 225.0, latitude: 40.778574, longitude: -73.951319)
            
        }
        else {
            print("System can't track regions")
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.strokeColor = UIColor.red
        circleRenderer.lineWidth = 1.0
        return circleRenderer
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        //showAlert("enter \(region.identifier)")
        print("Geofence detected")
        geofenceTriggered(region.identifier)
        monitoredRegions[region.identifier] = Date()
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        //showAlert("exit \(region.identifier)")
        monitoredRegions.removeValue(forKey: region.identifier)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let date = NSDate()
        
        //Debug Logging
        print(date.description + " at " + String(locations[0].coordinate.latitude))
        
        //Write to debug file
        var theDebug = String()
        theDebug = date.description(with: Locale.current) + " at " + String(locations[0].coordinate.latitude) + ", " + String(locations[0].coordinate.longitude) + "\n"
        
        writeDebugLog(theDebug)
        updateRegionsWithLocation(locations[0])
    }
    
    // MARK: - Comples business logic
    
    func updateRegionsWithLocation(_ location: CLLocation) {
        
        let regionMaxVisiting = 10.0
        var regionsToDelete: [String] = []
        
        for regionIdentifier in monitoredRegions.keys {
            if Date().timeIntervalSince(monitoredRegions[regionIdentifier]!) > regionMaxVisiting {
                //showAlert("Thanks for visiting")
                
                regionsToDelete.append(regionIdentifier)
            }
        }
        
        for regionIdentifier in regionsToDelete {
            monitoredRegions.removeValue(forKey: regionIdentifier)
        }
        
    }
    
    // MARK: - Helpers
    
    func showAlert(_ title: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        do{
            try mAudioSession?.setActive(false)
            mStopButton?.setImage(nil, for: .normal)
        }
        catch{
        }
    }
    
    func addGeoAnnotation(_ name: String, radius: Double, latitude: Double, longitude: Double ) {
        
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: location.latitude,
                                                                     longitude: location.longitude), radius: radius, identifier: name)
        locationManager.startMonitoring(for: region)
        
        // setup annotation
        let poiAnnotation = MKPointAnnotation()
        poiAnnotation.coordinate = location;
        poiAnnotation.title = "\(name)";
        mapView.addAnnotation(poiAnnotation)
        
        // setup circle
        let circle = MKCircle(center: location, radius: radius)
        mapView.add(circle)
    }
    
    func geofenceTriggered(_ name: String) {
        print("Triggered " + name)
        
        do{
            let theDebug = "Playing " + name + "\n"
            writeDebugLog(theDebug)
            
            if( mAudioPlayer != nil){
                if !((mAudioPlayer?.isPlaying)!) {
                    try mAudioSession?.setActive(true)
                    mAudioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: name, ofType: "mp3" )!))
                    mAudioPlayer?.prepareToPlay()
                    mAudioPlayer?.play()
                    mStopButton?.setImage(#imageLiteral(resourceName: "StopButton.png"), for: .normal)
                }
            }
            else{
                mAudioPlayer = AVAudioPlayer()
                try mAudioSession?.setActive(true)
                mAudioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: name, ofType: "mp3" )!))
                mAudioPlayer?.prepareToPlay()
                mAudioPlayer?.play()
                mStopButton?.setImage(#imageLiteral(resourceName: "StopButton.png"), for: .normal)
            }
            
        }catch _ {
            print("No audio for "+name)
            writeDebugLog("No audio for "+name)
        }
    }
    
    func writeDebugLog(_ text: String) {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        
        let theDebugFilePath = "\(documentsDirectory)/NYCDebugFile2.txt"
        if mDebugFile == nil {
            mDebugFile? = FileHandle(forUpdatingAtPath: theDebugFilePath)!
        }
        mDebugFile?.seekToEndOfFile()
        mDebugFile?.write( text.data(using: String.Encoding.utf8)!)
        mDebugFile?.closeFile()
    }
    
}

