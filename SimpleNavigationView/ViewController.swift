//
//  ViewController.swift
//  SimpleNavigationView
//
//  Created by Akira Murao on 2022/05/20.
//

import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps
import MapboxNavigation
import CoreLocation

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Define two waypoints to travel between
        let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox")
        let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House")
        
        let simulatedCoordinate = CLLocationCoordinate2D(latitude: 38.915430135728734, longitude: -77.03236208251619)
        let simulatedDestination = Waypoint(coordinate: simulatedCoordinate, name: "Room & Board")
            
        let simlulatedRouteOptions = NavigationRouteOptions(waypoints: [origin, simulatedDestination])
        
        Directions.shared.calculate(simlulatedRouteOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let self = self else { return }
                
                guard let simulatedRoute = response.routes?.first else { return }
                print("simulatedRoute: \(simulatedRoute.description)")
                //let simulatedLocationManager = SimulatedLocationManager(route: simulatedRoute)
                let simulatedLocationManager = SimulatedRouteLocationManager(route: simulatedRoute)
                simulatedLocationManager.startUpdatingLocation()
                
                // Set options
                let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])
                
                // Request a route using MapboxDirections.swift
                Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
                    switch result {
                    case .failure(let error):
                        print(error.localizedDescription)
                    case .success(let response):
                        guard let self = self else { return }
                        
                        let navigationService = MapboxNavigationService(routeResponse: response,
                                                                        routeIndex: 0,
                                                                        routeOptions: routeOptions,
                                                                        routingProvider: NavigationSettings.shared.directions,
                                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                                        locationSource: simulatedLocationManager,
                                                                        simulating: .never)
                        
                        let viewController = NavigationViewController(navigationService: navigationService)
                        
                        if let mapView = viewController.navigationMapView?.mapView {
                            self.addCustomPointAnnotation(mapView: mapView, coordinate: simulatedCoordinate)
                            self.addLineAnnotation(mapView: mapView, route: simulatedRoute)
                        }
                        
                        viewController.delegate = self
                        viewController.modalPresentationStyle = .fullScreen
                        self.present(viewController, animated: true, completion: nil)
                    }
                }
            } // switch result
        } // Directions.shared.calculate(simlulatedRouteOptions)
    }
    
    private func addCustomPointAnnotation(mapView: MapView, coordinate: CLLocationCoordinate2D) {
        let pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        var customPointAnnotation = PointAnnotation(coordinate: coordinate)
        customPointAnnotation.image = .init(image: UIImage(named: "purple_pin")!, name: "purple_pin")
        pointAnnotationManager.annotations = [customPointAnnotation]
    }
    
    private func addLineAnnotation(mapView: MapView, route: Route) {
        guard let coordinates = route.shape?.coordinates else {
            return
        }
        
        var lineAnnotation = PolylineAnnotation(lineCoordinates: coordinates)
        
        lineAnnotation.lineColor = StyleColor(.purple)
        lineAnnotation.lineOpacity = 0.8
        lineAnnotation.lineWidth = 10.0
        
        let lineAnnnotationManager = mapView.annotations.makePolylineAnnotationManager()

        // Sync the annotation to the manager.
        lineAnnnotationManager.annotations = [lineAnnotation]
    }
}

extension ViewController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route) {
        print("\(route.description)")
    }
}

