import UIKit

class MemoryAndZoomUI: UIView {
    static let shared = MemoryAndZoomUI()
    
    let memoryLabel = UILabel()
    let firstImageView = UIImageView()
    let firstLabel = UILabel()
    let secondImageView = UIImageView()
    let secondLabel = UILabel()
    let settingsButton = UIButton(type: .custom)
    weak var delegate: MemoryAndZoomUIDelegate?

    private override init(frame: CGRect) {
        super.init(frame: CGRect(x: 230, y: 65, width: 150, height: 20))
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        secondImageView.translatesAutoresizingMaskIntoConstraints = false
        secondImageView.contentMode = .scaleAspectFit
        secondImageView.accessibilityIdentifier = "plusGlass"
        secondImageView.image = UIImage(systemName: "plus.magnifyingglass")
        addSubview(secondImageView)
        
        secondLabel.textColor = .systemBlue
        secondLabel.translatesAutoresizingMaskIntoConstraints = false
        secondLabel.accessibilityIdentifier = "Zoom"
        secondLabel.font = UIFont.boldSystemFont(ofSize: 14)
        addSubview(secondLabel)
        
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.accessibilityIdentifier = "gear"
        settingsButton.addTarget(self, action: #selector(handleSettingsButtonTap), for: .touchUpInside)
        
        addSubview(settingsButton)
        
        NSLayoutConstraint.activate([
            settingsButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            settingsButton.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            settingsButton.heightAnchor.constraint(equalTo: self.heightAnchor),
            settingsButton.widthAnchor.constraint(equalTo: settingsButton.heightAnchor),
            
            secondImageView.leadingAnchor.constraint(equalTo: settingsButton.trailingAnchor, constant: 3),
            secondImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            secondImageView.heightAnchor.constraint(equalTo: self.heightAnchor),
            secondImageView.widthAnchor.constraint(equalTo: secondImageView.heightAnchor),
            
            secondLabel.leadingAnchor.constraint(equalTo: secondImageView.trailingAnchor, constant: 3),
            secondLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            secondLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
    
    @objc private func handleSettingsButtonTap() {
        delegate?.didTapSettingsButton()
    }
}

protocol MemoryAndZoomUIDelegate: AnyObject {
    func didTapSettingsButton()
}
