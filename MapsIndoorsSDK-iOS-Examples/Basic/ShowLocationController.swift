import UIKit
import MapsIndoorsCore

class ShowLocationController: BaseMapController {
    
    override func setupController() async {
        if let location = await getRandomLocation()?.name {
            await selectLocation(locationName: location)
        }
    }
    
    func selectLocation(locationName: String) async {
        let query = MPQuery()
        let filter = MPFilter()
        
        query.query = locationName
        filter.take = 1
        
        let locations = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        if let firstLocation = locations.first {
            mapControl?.select(location: firstLocation, behavior: .default)
            mapControl?.select(floorIndex: firstLocation.floorIndex.intValue)
        }
    }
}
