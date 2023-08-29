import UIKit
import MapsIndoorsCore

class CustomInfoWindowController: BaseMapController {
    
    override func setupController() async {
        mapControl?.customInfoWindow = CustomInfoWindow()
        
        if let validLocation = await getRandomLocation() {
            mapControl?.select(location: validLocation, behavior: .default)
            mapControl?.select(floorIndex: validLocation.floorIndex.intValue)
        }
    }
}

class CustomInfoWindow: MPCustomInfoWindow {
    func infoWindowFor(location: MPLocation) -> UIView {
        let ui = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        ui.backgroundColor = UIColor.brown
        let label = UILabel.init(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
        label.textColor = UIColor.white
        label.text = "My Custom Info Window for \(location.name)"
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.backgroundColor = [UIColor.red, UIColor.green, UIColor.blue, UIColor.cyan, UIColor.magenta, UIColor.yellow][Int.random(in: 0...5)]
        ui.addSubview(label)
        return ui
    }
}
