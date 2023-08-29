import UIKit
import MapsIndoorsCore

class UseDelegatesController: BaseMapController {
    
    // Create the first UILabel for camera status
    private let cameraStatusLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemPink
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    // Create the second UILabel for didChange events
       private let changeStatusLabel: UILabel = {
           let label = UILabel()
           label.textColor = .systemTeal
           label.translatesAutoresizingMaskIntoConstraints = false
           label.numberOfLines = 0
           label.textAlignment = .center
           return label
       }()
    
    override func setupController() async {
        
        // Add the labels to the view and set their constraints
        view.addSubview(cameraStatusLabel)
        view.addSubview(changeStatusLabel)
        
        NSLayoutConstraint.activate([
            cameraStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cameraStatusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -60),
            cameraStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cameraStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            changeStatusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            changeStatusLabel.bottomAnchor.constraint(equalTo: cameraStatusLabel.topAnchor, constant: -10),
            changeStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            changeStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        // Setting the mapcontrol delegate to the newly created delegate class
        mapControl?.delegate = CustomDelegates(cameraStatusLabel: cameraStatusLabel, changeStatusLabel: changeStatusLabel)
        
        if let firstLocation = await getRandomLocation() {
            mapControl?.select(location: firstLocation, behavior: .default)
            mapControl?.select(floorIndex: firstLocation.floorIndex.intValue)
        }
    }
}

class CustomDelegates: MPMapControlDelegate {
    
    private weak var cameraStatusLabel: UILabel?
    private weak var changeStatusLabel: UILabel?
    
    init(cameraStatusLabel: UILabel, changeStatusLabel: UILabel) {
        self.cameraStatusLabel = cameraStatusLabel
        self.changeStatusLabel = changeStatusLabel
    }
    
    func cameraIdle() -> Bool {
        cameraStatusLabel?.text = "📽️ Idle..."
        return true
    }
    
    func cameraWillMove() -> Bool {
        cameraStatusLabel?.text = "📽️ Will move..."
        return true
    }
    
    func didChangeCameraPosition() -> Bool {
        cameraStatusLabel?.text = "📽️ Did move..."
        return true
    }
    
    func didChange(selectedBuilding: MPBuilding?) -> Bool {
        changeStatusLabel?.text = "Building changed"
        return true
    }
    
    func didChange(selectedLocation: MPLocation?) -> Bool {
        changeStatusLabel?.text = "Location changed"
        return true
    }
}
