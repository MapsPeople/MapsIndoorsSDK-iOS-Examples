import UIKit
import MapsIndoorsCore

class ShowBuildingController: BaseMapController {
    
    override func setupController() async {
        let buildings = await MPMapsIndoors.shared.buildings()
        if let firstBuilding = buildings.first {
            mapControl?.select(building: firstBuilding, behavior: .default)
        }
    }
}
