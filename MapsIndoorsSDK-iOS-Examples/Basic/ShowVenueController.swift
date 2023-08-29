import UIKit
import MapsIndoorsCore

class ShowVenueController: BaseMapController {
    
    override func setupController() async {
        let venues = await MPMapsIndoors.shared.venues()
        if let firstVenue = venues.first {
            mapControl?.select(venue: firstVenue, behavior: .default)
        }
    }
}
