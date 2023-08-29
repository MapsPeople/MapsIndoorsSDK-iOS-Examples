import UIKit
import MapsIndoors
import CoreLocation

class MyPositionProvider : NSObject, MPPositionProvider {
    
    var delegate: MPPositionProviderDelegate?
    var latestPosition: MPPositionResult?
    private var running = false
    
    init(mockAt: MPPoint) {
        latestPosition = MPPositionResult(coordinate: CLLocationCoordinate2D(latitude: mockAt.latitude, longitude: mockAt.longitude) , floorIndex: 10, accuracy: 20.0)
    }
    func updatePosition() {
        if running {
            latestPosition?.bearing = (latestPosition!.bearing + 10)
            latestPosition?.coordinate = generateRandomCoordinate()
            latestPosition?.bearing = Double.random(in: 0..<360)
            latestPosition?.accuracy = Double.random(in: 0..<10)
            
            if let delegate = self.delegate, let latestPosition = self.latestPosition {
                delegate.onPositionUpdate(position: latestPosition)
            }
            
            weak var _self = self
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                _self?.updatePosition()
            }
        }
    }

    func startPositioning(_ arg: String?) {
        running = true
        updatePosition()
    }

    func stopPositioning(_ arg: String?) {
        running = false
    }
    
    func generateRandomCoordinate() -> CLLocationCoordinate2D {
        // Define a small range for the random offset
        let offset: Double = 0.00001
        
        // Generate random offsets for latitude and longitude
        let latOffset = Double.random(in: -offset...offset)
        let lonOffset = Double.random(in: -offset...offset)
        
        // Create a new coordinate with the random offsets
        let newCoordinate = CLLocationCoordinate2D(latitude: (latestPosition?.coordinate.latitude ?? 0) + latOffset, longitude: (latestPosition?.coordinate.longitude ?? 0) + lonOffset)
        return newCoordinate
    }
    
}
