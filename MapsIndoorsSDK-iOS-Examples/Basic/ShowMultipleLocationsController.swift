import UIKit
import MapsIndoorsCore

class ShowMultipleLocationsController: BaseMapController {
    let locationCategories = ["Canteen", "Kitchen", "Restroom", "Stairs"]
    
    override func setupController() async {
        // Any other functions that rely on the SDK being loaded
        mapControl = MPMapsIndoors.createMapControl(mapConfig: MapEngine.selectedMapConfig!)
        await selectLocations(locationCategories: locationCategories)
    }
    
    func selectLocations(locationCategories: [String]) async {
        let query = MPQuery()
        let filter = MPFilter()
        
        filter.types = locationCategories
        //filter.take = 1
        
        let locations = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        if let firstLocation = locations.first {
            mapControl?.select(floorIndex: firstLocation.floorIndex.intValue) // You are not guaranteed that the visible floor contains any search results, so that is why we change floor
            mapControl?.setFilter(locations: locations, behavior: .default)
            if let centerCoordinate = firstLocation.coordinateBounds?.bounds.center.coordinate {
                MapEngine.selectedMapProvider?.setCamera(coordinates: centerCoordinate, zoom: 19)
            }
        }
    }
}
