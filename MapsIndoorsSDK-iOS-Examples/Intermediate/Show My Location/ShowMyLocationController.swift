import MapsIndoors
import MapsIndoorsCore
import UIKit

/***
 ---
 title: Show the Blue Dot with MapsIndoors - Part 2
 ---

 This is part 2 of the tutorial of managing a blue dot on the map. [In Part 1 we created the position provider](showmylocationmypositionprovider). Now we will create a view controller displaying a map that shows the users (mock) location.

 Create a class `ShowMyLocationController` that inherits from `BaseMapController`.
 ***/
class ShowMyLocationController: BaseMapController {
    var originalIcon: UIImage?

    var locationButton: UIButton!

    override func setupController() async {
        if let validPosition = await getRandomLocation()?.position {
            let provider = MyPositionProvider(mockAt: validPosition)

            MPMapsIndoors.shared.positionProvider = provider
            mapControl?.showUserPosition = true

            provider.startPositioning(nil)

            if let dr = MPMapsIndoors.shared.displayRuleFor(displayRuleType: .blueDot) {
                originalIcon = dr.icon
            }
        }
        setupLocationButton()
    }

    func setupLocationButton() {
        locationButton = UIButton(type: .system)
        locationButton.setTitle("Toggle Icon", for: .normal)
        locationButton.backgroundColor = UIColor(red: 75 / 255, green: 125 / 255, blue: 124 / 255, alpha: 0.6)
        locationButton.addTarget(self, action: #selector(changeIcon), for: .touchUpInside)

        // Create a stack view
        let stackView = UIStackView(arrangedSubviews: [locationButton])
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

    @objc func changeIcon() {
        if let dr = MPMapsIndoors.shared.displayRuleFor(displayRuleType: .blueDot) {
            if dr.icon == originalIcon {
                dr.icon = createLocationMarker()
            } else {
                dr.icon = originalIcon
            }
        }
    }

    // create a blue colored dot
    func createLocationMarker() -> UIImage {
        let size = CGSize(width: 25, height: 25)

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()

        // Draw the blue dot
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fillEllipse(in: rect)

        // Draw the arrow
        context?.setFillColor(UIColor.white.cgColor) // Arrow color
        let arrowWidth: CGFloat = 6.0
        let arrowHeight: CGFloat = 10.0
        let arrowPath = UIBezierPath()
        arrowPath.move(to: CGPoint(x: size.width / 2, y: 5)) // Top point of the arrow
        arrowPath.addLine(to: CGPoint(x: size.width / 2 - arrowWidth / 2, y: 5 + arrowHeight))
        arrowPath.addLine(to: CGPoint(x: size.width / 2 + arrowWidth / 2, y: 5 + arrowHeight))
        arrowPath.close()
        context?.addPath(arrowPath.cgPath)
        context?.fillPath()

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image ?? UIImage()
    }

    override func adjustUI(forMenu: Bool) {
        locationButton.isHidden = forMenu
    }

    override func updateForBuildingChange() {
        if locationButton != nil {
            locationButton.isHidden = false
        }
    }
}
