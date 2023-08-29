import UIKit
import MapsIndoorsCore
import MapsIndoors
/***
 ---
 title: Performing Display Rule modifications in MapsIndoors
 ---
 
 In this tutorial we will toggle the visibility of `MPLocation` of a specific type by modifying the DisplayRule
 
 ***/
class ToggleLocationsVisibilityController: BaseMapController {
    
    var filterType1 = "Storage"
    var filterType2 = "Kitchen"
    
    override func setupController() async {
        // Ceack if Type for MPLocation is valid for this solution
        if await !isTypeValidForSolution(type: filterType1) {
            filterType1 = await changeType()
        }
        if await !isTypeValidForSolution(type: filterType2) {
            filterType2 = await changeType()
        }
        
        // Create buttons
        let typeButton = createButton(title: "Toggle-Type", selector: #selector(typeButtonTapped))
        let locationButton = createButton(title: "Toggle-Location", selector: #selector(locationButtonTapped))
        let multipleButton = createButton(title: "Toggle-Multiple-Type", selector: #selector(multipleTypeButtonTapped))
        
        // Create a stack view
        let stackView = UIStackView(arrangedSubviews: [typeButton, locationButton, multipleButton])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Add constraints
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
        ])
    }
    
    // Button actions
    @objc func typeButtonTapped() {
        toggleTypeVisibility()
    }
    
    @objc func locationButtonTapped() {
        Task {
            await toggleLocationVisibility()
        }
    }
    
    @objc func multipleTypeButtonTapped() {
        Task {
            await toggleMultipleTypeVisibility()
        }
    }
    
    func toggleTypeVisibility() {
        // Select a location close to filterType1 to move the camera there
        Task { await moveNear(type: filterType1) }
        
        DispatchQueue.main.async() {
            if let disRul = MPMapsIndoors.shared.displayRuleFor(type: self.filterType1) {
                disRul.visible.toggle()
                if let mpcontrol = self.mapControl {
                    mpcontrol.refresh()
                }
            }
        }
    }
    
    func toggleLocationVisibility() async {
        // Select a location close to filterType1 to move the camera there
        await moveNear(type: filterType1)
        
        let filter = MPFilter()
        let query = MPQuery()
        
        filter.types = [filterType1]
        let locations = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        for location in locations {
            if let displayRule = MPMapsIndoors.shared.displayRuleFor(location: location) {
                displayRule.visible.toggle()
                MPMapsIndoors.shared.set(displayRule: displayRule, location: location)
            }
        }
        mapControl?.refresh()
    }
    
    func toggleMultipleTypeVisibility() async {
        // Select a location close to filterType2 to move the camera there
        await moveNear(type: filterType2)
        
        let filter = MPFilter()
        let query = MPQuery()
        
        filter.types = [filterType1]
        let locationsofTypeOne = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        for location in locationsofTypeOne {
            if let displayRule = MPMapsIndoors.shared.displayRuleFor(location: location) {
                displayRule.visible.toggle()
                MPMapsIndoors.shared.set(displayRule: displayRule, location: location)
            }
        }
        
        filter.types = [filterType2]
        let locationsofTypeTwo = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        for location in locationsofTypeTwo {
            if let displayRule = MPMapsIndoors.shared.displayRuleFor(location: location) {
                displayRule.visible.toggle()
                MPMapsIndoors.shared.set(displayRule: displayRule, location: location)
            }
        }
        
        mapControl?.refresh()
    }
    
    func createButton(title: String, selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: selector, for: .touchUpInside)
        button.backgroundColor = UIColor(red: 35/255, green: 85/255, blue: 84/255, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
    
    func moveNear(type: String) async {
        let query = MPQuery()
        let filter = MPFilter()
        
        let allLocations = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        
        if let validBuilding = currentBuilding {
            let typeFilteredLocations = allLocations.filter({ $0.building == validBuilding.administrativeId && $0.type == type })
            if let focusLocation = typeFilteredLocations.first {
                if let centerCoordinate = focusLocation.coordinateBounds?.bounds.center.coordinate {
                    MapEngine.selectedMapProvider?.setCamera(coordinates: centerCoordinate, zoom: 21)
                    mapControl?.select(floorIndex: focusLocation.floorIndex.intValue)
                }
            }
        }
    }
    
    func isTypeValidForSolution(type: String) async -> Bool {
        
        let query = MPQuery()
        let filter = MPFilter()
        
        let allLocations = await MPMapsIndoors.shared.locationsWith(query: query, filter: filter)
        if let locationWithValidType = allLocations.first(where: {$0.type == type}) {
            return true
        }
        return false
    }
    
    func changeType() async -> String {
        if let randomLocation = await getRandomLocation() {
            return randomLocation.type
        }
        return ""
    }
}
