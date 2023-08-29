import UIKit
import MapsIndoors
import MapsIndoorsCore

class CustomFloorSelectorController: BaseMapController {
    
    var selectionBehavior: MPSelectionBehavior = .default
    
    override func setupController() async {
        selectionBehavior.showInfoWindow = false
        
        await setupFloorSelector()
    }
    
    func setupFloorSelector() async {
        // Calculate the size of the floor selector based on the number of floors and the size of the buttons
        let buttonHeight: CGFloat = 50
        let buttonWidth: CGFloat = 50
        
        // Get all the buildings
        let buildings = await MPMapsIndoors.shared.buildings()
        // Get the ID for the currently selected building
        if let adminId = currentBuilding?.administrativeId {
            // Filter for the building
            if let building = buildings.first(where: { $0.administrativeId == adminId }) {
                if let numberOfFloors = building.floors?.count {
                    let floorSelectorHeight = CGFloat(numberOfFloors) * buttonHeight
                    let floorSelectorWidth = buttonWidth
                    
                    //Initialize a custom floor selector with a CGRect
                    let customFloorSelector = MyFloorSelector(frame: CGRect(x: 40, y: 150, width: floorSelectorWidth, height: floorSelectorHeight))
                    if let currentFloor = mapControl?.selectedLocation?.floorIndex {
                        customFloorSelector.initialFloor = currentFloor
                    }
                    
                    //Set the mapControl´s floorSelector to your newly created floorSelector
                    mapControl?.floorSelector = customFloorSelector
                }
            }
        }
    }
}

//Custom Floor selector class that conforms to both UIView and MPCustomFloorSelector
class MyFloorSelector: UIView, MPCustomFloorSelector {
    
    var initialFloor: NSNumber?
    
    var floorButtons: [UIButton] = []
    var currentFloorButton: UIButton?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func remove() {
        removeFromSuperview()
    }
    
    var building: MapsIndoors.MPBuilding?
    
    var delegate: MapsIndoors.MPFloorSelectorDelegate?
    
    var floorIndex: NSNumber? {
        didSet {
            updateCurrentFloorButton()
        }
    }
    
    func onShow() {
        //Shows the floor selector
        self.isHidden = false
        createFloorButtons()
        updateCurrentFloorButton()
    }
    
    func onHide() {
        //Hides the floor selector
        self.isHidden = true
    }
    
    func createFloorButtons() {
        // Remove existing buttons
        for button in floorButtons {
            button.removeFromSuperview()
        }
        floorButtons.removeAll()
        
        guard let floors = building?.floors else { return }
        
        let buttonHeight: CGFloat = 50
        let buttonWidth: CGFloat = 50  // Increased width
        var yOffset: CGFloat = 0
        let xOffset: CGFloat = 20  // Offset from the left of the screen
        
        // Sort the floors by their floorIndex
        let sortedFloors = floors.sorted { $0.value.floorIndex?.intValue ?? 0 < $1.value.floorIndex?.intValue ?? 0 }
        
        for (_, floor) in sortedFloors {
            let floorButton = UIButton(frame: CGRect(x: xOffset, y: yOffset, width: buttonWidth, height: buttonHeight))
            floorButton.backgroundColor = .cyan
            floorButton.setTitle(floor.name, for: .normal)  // Set the button title to the floor name
            floorButton.addTarget(self, action: #selector(floorButtonTapped), for: .touchUpInside)
            self.addSubview(floorButton)
            floorButtons.append(floorButton)
            yOffset += buttonHeight
        }
    }
    
    @objc func floorButtonTapped(sender: UIButton!) {
        guard let floorName = sender.title(for: .normal),
              let floor = building?.floors?.first(where: { $0.value.name == floorName }),  // Find the floor using the floor name
              let floorIndex = floor.value.floorIndex else { return }
        
        // Update the floor index
        self.floorIndex = floorIndex
        
        // Notify the delegate
        delegate?.onFloorIndexChanged(floorIndex)
    }
    
    func updateCurrentFloorButton() {
        // Reset the color of the previous current floor button
        currentFloorButton?.backgroundColor = .cyan
        
        // Find the button corresponding to the current floor using the floor name
        currentFloorButton = floorButtons.first(where: { $0.title(for: .normal) == building?.floors?.first(where: { $0.value.floorIndex == floorIndex })?.value.name })
        
        // Change the color of the current floor button
        currentFloorButton?.backgroundColor = .blue
    }
}
