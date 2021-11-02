//
//  MapView.swift
//  WanderFinder
//
//  Created by admin on 27.10.21.
//

import UIKit
import CoreLocation
import MapKit

class MapView: UIViewController {
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var pin: UIImageView!
    
    let locationManager = CLLocationManager()
    let regionInMeter : Double = 4000
    var previousLocation: CLLocation?
    var directionsArray: [MKDirections] = []
    
    let home: CLLocation = CLLocation(latitude: 52.513299, longitude: 13.500637)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationServices()

    }
    
    func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerUserLocationOnMap() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeter, longitudinalMeters: regionInMeter)
            map.setRegion(region, animated: true)
        }
    }
    
    
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            // show alert letting user know we need Location turned on
        }
    }
    
    func checkLocationAuthorization(){
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse:
            // Do Map Stuff
            startTrackingUserLocation()
        case .denied:
            locationManager.requestWhenInUseAuthorization()
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            // Show alert
            break
        case .authorizedAlways:
            break
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func startTrackingUserLocation(){
        map.showsUserLocation = true
        centerUserLocationOnMap()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: map)
    }
    
    
    func getCenterLocation(for map: MKMapView) -> CLLocation {
        let latitude = map.centerCoordinate.latitude
        let longitude = map.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    
    func getDirections() {
        guard let location = locationManager.location?.coordinate else {
            // Inform user we dont get the current location
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        
        directions.calculate { [self] (response, error) in
            
            guard let response = response else {return}
            
            for route in response.routes {
                self.map.addOverlay(route.polyline)
                self.map.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60), animated: true)
            }
            
        }
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoordinate   = getCenterLocation(for: map).coordinate
        let startingLocation        = MKPlacemark(coordinate: coordinate)
        let destination             = MKPlacemark(coordinate: destinationCoordinate)
        
        let request                 = MKDirections.Request()
        request.source              = MKMapItem(placemark: startingLocation)
        request.destination         = MKMapItem(placemark: destination)
        request.transportType       = .walking
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func resetMapView(withNew directions: MKDirections) {
        map.removeOverlays(map.overlays)
        directionsArray.append(directions)
        let _ = directionsArray.map {
            $0.cancel()
        }
        directionsArray.removeAll()
        
    }
    
    
    @IBAction func goButtonTapped(_ sender: UIButton) {
        getDirections()
        pin.alpha = 0
    }
    


}

extension MapView: CLLocationManagerDelegate {
    
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        // everytime Location Updates
//        guard let location = locations.last else { return }
//        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeter, longitudinalMeters: regionInMeter)
//        map.setRegion(region, animated: true)
//    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
}

extension MapView: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        
        let center = getCenterLocation(for: map)
        let geoCoder = CLGeocoder()
        
        if center.isEqual(previousLocation) {
            pin.alpha = 0
        } else {
            pin.alpha = 1
        }
        
        geoCoder.cancelGeocode()
        
        guard center.distance(from: previousLocation ?? center) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let _ = error {
                //TODO: Show alert informing the user
                return
            }
            
            guard let placemark = placemarks?.first else {
                //TODO: Show alert informing the user
                return
            }
            
            
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.adressLabel.text = "\(streetName) \(streetNumber)"
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd renderers: [MKOverlayRenderer]) {
        pin.alpha = 0
        previousLocation = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = UIColor(red: 0, green: 139, blue: 147, alpha: 0.5)
        return renderer
        
    }
}
