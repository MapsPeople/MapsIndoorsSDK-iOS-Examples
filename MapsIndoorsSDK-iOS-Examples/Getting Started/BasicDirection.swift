import Foundation
import UIKit
import MapsIndoorsCore
import MapsIndoors

class BasicDirection: BaseMapController {
    
    var directionsRenderer: MPDirectionsRenderer?
    var origin, destination: MPLocation?
    
    override func setupController() async {
        origin = await getRandomLocation()
        destination = await getRandomLocation()
        
        if let validLocation = destination {
            await directions(to: validLocation)
        }
        
    }
    
    func directions(to destination: MPLocation) async {
        if directionsRenderer == nil {
            directionsRenderer = mapControl!.newDirectionsRenderer()
        }
        let directionsQuery = MPDirectionsQuery(origin: origin!, destination: destination)
        
        do {
            let route = try await MPMapsIndoors.shared.directionsService.routingWith(query: directionsQuery)
            directionsRenderer?.route = route
            directionsRenderer?.routeLegIndex = 0
            directionsRenderer?.animate(duration: 5)
        } catch {
            print(error.localizedDescription)
        }
    }
}
