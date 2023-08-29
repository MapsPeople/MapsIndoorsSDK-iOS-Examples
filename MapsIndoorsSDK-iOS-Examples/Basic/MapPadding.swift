import UIKit
import MapsIndoorsCore

class MapPadding: BaseMapController {
    
    override func setupController() async {
        
        // Creating a simple red view for the demo
        let testView = UIView()
        testView.translatesAutoresizingMaskIntoConstraints = false
        testView.backgroundColor = .red
        self.view.addSubview(testView)
        
        // Adding Auto Layout constraints for the red view
        testView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        testView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        testView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        testView.heightAnchor.constraint(equalToConstant: 250).isActive = true
        
        // Adjusting the map control's padding to match the red view's height
        // Adjust the bottom padding value as needed
        mapControl?.mapPadding = UIEdgeInsets(top: 0, left: 0, bottom: 250, right: 0)
    }
}
