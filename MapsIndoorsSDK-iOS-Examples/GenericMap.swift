//
//  GenericMap.swift
//  MapsIndoorsSDK-iOS-Examples
//
//  Created by M. Faizan Satti on 24/08/2023.
//

import Foundation
import MapsIndoorsCore
import GoogleMaps

protocol GenericMap {
    
    func setup()
    
    var view : UIView { get }
    
    var delegate : GenericMapDelegate? {get set}
    
    var padding : UIEdgeInsets { get set }
        
    var target : CLLocationCoordinate2D { get set }
        
    var bearing : Double { get set }
        
    var tilt : Double { get set }
        
    var zoom : Double { get set }
        
    var visibleRegion : MPGeoRegion { get }
    
    func animate(bounds: MPGeoBounds)
    
    func setCamera(coordinates: CLLocationCoordinate2D, zoom: Float)
        
    func move(target: CLLocationCoordinate2D, zoom: Double, bearing: Double, tilt: Double)
                
    func fit(northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D, padding: Float)
        
    func fit(northEast: CLLocationCoordinate2D, southWest: CLLocationCoordinate2D, edgeInsets: UIEdgeInsets)
    
}

protocol GenericMapDelegate {
    
    func cameraMoved()
    
    func cameraIdle()
    
}

protocol GoogleMapSpecific {
    func setCamera(update: GMSCameraUpdate)
}
