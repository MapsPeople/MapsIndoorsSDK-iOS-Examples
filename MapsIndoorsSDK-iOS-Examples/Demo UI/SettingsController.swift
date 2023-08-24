//
//  SettingsController.swift
//  MapsIndoorsSDK-iOS-Examples
//
//  Created by M. Faizan Satti on 24/08/2023.
//

import Foundation
import UIKit
import MapsIndoorsCore
import GoogleMaps
import GoogleMapsCore
import MapboxMaps

class SettingsController: UIViewController {
    
    @IBOutlet weak var solutionLabel: UILabel!
    
    @IBOutlet weak var memoryLabel: UILabel!
    
    @IBOutlet weak var currentDisplayrule: UILabel!
    
    public var MBMapView: MapView? = nil
    public var gMapView: GMSMapView? = nil
    
    @IBAction func logOut(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(identifier: "startPage1") as! StartPage
        
        // Removing all data - MapsIndoors
        MapEngine.APIKey = nil
        MapEngine.selectedMapView = nil
        MapEngine.selectedMapProvider = nil
        MapEngine.selectedMapConfig = nil
        MapEngine.selectedMapView?.removeFromSuperview()
        MPMapsIndoors.shared.shutdown()
        
        // Removing all data to save memory - Google
        gMapView?.clear()
        gMapView?.delegate = nil
        gMapView?.removeFromSuperview()
        gMapView = nil
        
        // Removing all data to save memory - MapBox
        MBMapView?.removeFromSuperview()
        MBMapView = nil
        
        // Removing the memory from all previous view controllers
        if let navigationController = self.navigationController {
            navigationController.popToRootViewController(animated: true)
        }
        
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLoad() {
        osVersion()
        MPVersion()
        
        solutionLabel.text = MapEngine.APIKey
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.updateMemoryLabel()
        }
    }
    
    //Memory - keep in mind that this value represents the physical memory footprint, which includes both resident memory and memory that has been swapped out to disk.
    func updateMemoryLabel() {
        let usedMemory = getUsedMemory()
        let memoryUsage = ByteCountFormatter.string(fromByteCount: Int64(usedMemory), countStyle: .memory)
        memoryLabel.text = "\(memoryUsage)"
    }
    
    func getUsedMemory() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        let usedMemory = UInt64(info.phys_footprint)
        
        return usedMemory
    }
    
    func osVersion() {
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        currentDisplayrule.text = "iOS: \(os)"
    }
    
    @IBOutlet weak var sdkLabel: UILabel!
    
    func MPVersion() {
        let buildNumber = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        sdkLabel.text = "SDK: \(buildNumber!)"
    }
}
