import UIKit
import MapsIndoorsCore

class ShowFloorController: BaseMapController {
    
    override func setupController() async {
        
        let location = await MPMapsIndoors.shared.locationsWith(query: nil, filter: nil)
        if let firstLocation = location.first {
            mapControl?.select(location: firstLocation, behavior: .default)
            // Selecting a specific floor.
            mapControl?.select(floorIndex: firstLocation.floorIndex.intValue)
        }
    }
}
