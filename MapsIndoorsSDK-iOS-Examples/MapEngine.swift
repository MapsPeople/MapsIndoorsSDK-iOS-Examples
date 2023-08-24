//
//  MapEngine.swift
//  MapsIndoorsSDK-iOS-Examples
//
//  Created by M. Faizan Satti on 24/08/2023.
//

import Foundation
import MapsIndoorsCore

class MapEngine {
    static var selectedMapView: UIView?
    static var selectedMapConfig: MPMapConfig?
    static var selectedMapProvider: GenericMap?
    static var APIKey: String?
    
    static func clearSelectedMapView() {
        // Remove the selected map view from its superview and set it to nil
        selectedMapView?.removeFromSuperview()
        selectedMapView = nil
    }
}
