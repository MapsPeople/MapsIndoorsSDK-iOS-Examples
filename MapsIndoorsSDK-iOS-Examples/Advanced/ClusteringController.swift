import UIKit
import MapsIndoorsCore
import MapsIndoors

/***
 ---
 title: Work with location grouping / clustering
 ---
 
 This is an example of enabling and disabling location grouping on the map as well as providing custom cluster tapping behavior and custom cluster images.
 
 Start by creating a  class that conforms to the `MPMapControlDelegate` protocol and the `MPCustomClusterIcon` protocol
 ***/
class ClusteringController: BaseMapController, MPMapControlDelegate, MPCustomClusterIcon {
    let clusteringButton = UIButton.init()
    let iconToggleButton = UIButton.init()
    
    override func setupController() async {
        mapControl?.delegate = self
        mapControl?.customClusterIcon = self
        
        /***
         Setup buttons that enables/disables the location grouping / clustering mechanism and the icon from default <=> custom
         ***/
        setupButton(button: iconToggleButton, title: "Cluster Custom Icon", action: #selector(toggleIcon))
        setupButton(button: clusteringButton, title: "Clustering disabled", action: #selector(toggleClustering))
        
        // Create a stack view
        let stackView = UIStackView(arrangedSubviews: [clusteringButton, iconToggleButton])
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
    
    func setupButton(button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.backgroundColor = UIColor(red: 35/255, green: 85/255, blue: 84/255, alpha: 0.7)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.clipsToBounds = true
        button.translatesAutoresizingMaskIntoConstraints = false // Enable Auto Layout for the button
    }
    
    /***
     Define an objective-c method `toggleClustering` that will receive events from your button, and toggle the clustering flag:
     * Check current state
     * Swap state
     * Make button reflect the state
     * Force re-render map
     ***/
    @objc func toggleClustering() {
        if (MPMapsIndoors.shared.solution?.config.enableClustering) != nil {
            MPMapsIndoors.shared.solution?.config.enableClustering.toggle()
            clusteringButton.isSelected.toggle()
            
            // Update button title
            if clusteringButton.isSelected {
                clusteringButton.setTitle("Clustering enabled", for: .normal)
            } else {
                clusteringButton.setTitle("Clustering disabled", for: .normal)
            }
            
            mapControl?.refresh()
        }
    }
    
    /***
     Define an objective-c method `toggleIcon` that will receive events from your button, and toggle the icon flag:
     * Check current state
     * Swap state
     * Make button reflect the state
     * Force re-render map
     ***/
    @objc func toggleIcon() {
        iconToggleButton.isSelected.toggle()
        
        // Update button title
        if iconToggleButton.isSelected {
            iconToggleButton.setTitle("Cluster Default Icon", for: .normal)
            mapControl?.customClusterIcon = nil // Use default icon
        } else {
            iconToggleButton.setTitle("Cluster Custom Icon", for: .normal)
            mapControl?.customClusterIcon = self // Use custom icon
        }
        
        mapControl?.refresh()
    }
    
    /***
     * Implement the `clusterIconFor` to provide custom icons for clusters
     **/
    func clusterIconFor(type: String, size: Int) -> UIImage {
        let clusterSize = CGSize(width: 30, height: 30)
        let renderer = UIGraphicsImageRenderer(size: clusterSize)
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.red.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.white.cgColor)
            ctx.cgContext.setLineWidth(2)
            
            let rectangle = CGRect(x: 0, y: 0, width: clusterSize.width, height: clusterSize.height)
            ctx.cgContext.addEllipse(in: rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.white
            ]
            
            let text = NSAttributedString(string: "\(size)", attributes: attributes)
            let textSize = text.size()
            let textPoint = CGPoint(x: (clusterSize.width - textSize.width) / 2, y: (clusterSize.height - textSize.height) / 2)
            text.draw(at: textPoint)
        }
        return img
    }
    
    override func adjustUI(forMenu: Bool) {
        clusteringButton.isHidden = forMenu
        iconToggleButton.isHidden = forMenu
    }
    
    override func updateForBuildingChange() {
        clusteringButton.isHidden = false
        iconToggleButton.isHidden = false
    }
}
