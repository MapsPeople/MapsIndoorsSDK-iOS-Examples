import UIKit
import MapsIndoorsCore
import MapsIndoors

class SelectionController: BaseMapController {
    
    // Buttons
    private var selectVenueButton: UIButton!
    private var selectBuildingButton: UIButton!
    private var selectFloorButton: UIButton!
    private var selectLocationButton: UIButton!
    
    // Labels
    private var venueTitleLabel: UILabel!
    private var venueSubtitleLabel: UILabel!
    private var buildingTitleLabel: UILabel!
    private var buildingSubtitleLabel: UILabel!
    private var floorTitleLabel: UILabel!
    private var floorSubtitleLabel: UILabel!
    private var locationTitleLabel: UILabel!
    private var locationSubtitleLabel: UILabel!
    
    override func setupController() async {
        hideSideMenuButton()
        setupButtons()
    }
    
    private func hideSideMenuButton() {
        menuButton.isHidden = true
    }
    
    private func setupButtons() {
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 50
        let spacing: CGFloat = 20
        let initialY: CGFloat = 650
        let initialX: CGFloat = 40
        
        // Venue Button
        (selectVenueButton, venueTitleLabel, venueSubtitleLabel) = createButton(frame: CGRect(x: initialX, y: initialY, width: buttonWidth, height: buttonHeight), title: "Select Venue", subtitle: "Choose venues", action: #selector(selectVenueTapped))
        
        // Building Button
        (selectBuildingButton, buildingTitleLabel, buildingSubtitleLabel) = createButton(frame: CGRect(x: initialX + buttonWidth + spacing, y: initialY, width: buttonWidth, height: buttonHeight), title: "Select Building", subtitle: "Choose buildings", action: #selector(selectBuildingTapped))
        
        // Floor Button
        (selectFloorButton, floorTitleLabel, floorSubtitleLabel) = createButton(frame: CGRect(x: initialX, y: initialY + buttonHeight + spacing, width: buttonWidth, height: buttonHeight), title: "Select Floor", subtitle: "Choose floors", action: #selector(selectFloorTapped))
        
        // Location Button
        (selectLocationButton, locationTitleLabel, locationSubtitleLabel) = createButton(frame: CGRect(x: initialX + buttonWidth + spacing, y: initialY + buttonHeight + spacing, width: buttonWidth, height: buttonHeight), title: "Select Location", subtitle: "Choose locations", action: #selector(selectLocationTapped))
    }
    
    private func createButton(frame: CGRect, title: String, subtitle: String, action: Selector) -> (UIButton, UILabel, UILabel) {
        // Create button
        let button = UIButton(frame: frame)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
        // Create title label
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 5, width: frame.width, height: 30))
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        button.addSubview(titleLabel)
        // Create subtitle label
        let subtitleLabel = UILabel(frame: CGRect(x: 0, y: 30, width: frame.width, height: 25))
        subtitleLabel.text = subtitle
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .white
        button.addSubview(subtitleLabel)
        
        return (button, titleLabel, subtitleLabel)
    }
    
    @objc func selectVenueTapped(_ sender: UIButton) {
        venueSubtitleLabel.text = "Updating..."
        Task {
            let allVenues = await MPMapsIndoors.shared.venues()
            self.presentActionSheet(title: "Select a Venue", items: allVenues, display: { $0.name! }) { selectedVenue in
                self.mapControl?.select(venue: selectedVenue, behavior: .default)
                self.venueTitleLabel.text = "Change Venue"
                self.venueSubtitleLabel.text = "Currently: \(selectedVenue.name!)"
            }
        }
    }
    
    @objc func selectBuildingTapped(_ sender: UIButton) {
        buildingSubtitleLabel.text = "Updating..."
        Task {
            let allBuildings = await MPMapsIndoors.shared.buildings()
            self.presentActionSheet(title: "Select a Building", items: allBuildings, display: { $0.name! }) { selectedBuilding in
                self.mapControl?.select(building: selectedBuilding, behavior: .default)
                self.buildingTitleLabel.text = "Change Building"
                self.buildingSubtitleLabel.text = "Currently: \(selectedBuilding.name!)"
            }
        }
    }
    
    @objc func selectFloorTapped(_ sender: UIButton) {
        floorSubtitleLabel.text = "Updating..."
        if let allFloors = mapControl?.currentBuilding?.floors {
            // Convert the dictionary values to an array of MPFloor objects
            let floorArray = Array(allFloors.values)
            
            self.presentActionSheet(title: "Select a Floor", items: floorArray, display: { $0.name }) { selectedFloor in
                // Select the floor and move the camera there
                self.mapControl?.select(floorIndex: selectedFloor.floorIndex!.intValue)
                // Update the button title and subtitle
                self.floorTitleLabel.text = "Change Floor"
                self.floorSubtitleLabel.text = "Currently: \(selectedFloor.name)"
                self.mapControl?.refresh() // force re-render map view so the default floor selector updates
            }
        }
    }
    
    @objc func selectLocationTapped(_ sender: UIButton) {
        locationSubtitleLabel.text = "Loading..."
        Task {
            let allUnFilteredLocations = await MPMapsIndoors.shared.locationsWith(query: MPQuery(), filter: MPFilter())
            guard let validBuilding = mapControl?.currentBuilding else {
                locationSubtitleLabel.text = "Invalid building"
                return
            }
            
            let allocations = allUnFilteredLocations.filter({ $0.building == validBuilding.administrativeId })
            
            self.presentActionSheet(title: "Select a Location", items: allocations, display: { $0.name }) { selectedLocation in
                self.mapControl?.select(location: selectedLocation, behavior: .default)
                self.locationTitleLabel.text = "Change Location"
                self.locationSubtitleLabel.text = "Currently: \(selectedLocation.name)"
            }
        }
    }
    
    func presentActionSheet<T>(title: String, items: [T], display: (T) -> String, selection: @escaping (T) -> Void) {
        let actionSheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        for item in items {
            let action = UIAlertAction(title: display(item), style: .default) { _ in
                selection(item)
            }
            actionSheet.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        DispatchQueue.main.async {
            self.present(actionSheet, animated: true, completion: nil)
        }
    }
}
