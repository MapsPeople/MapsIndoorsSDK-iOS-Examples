import Foundation
import UIKit
import MapsIndoorsCore

class BasicLiveData: BaseMapController {
    // TODO: closure does not work properly, a bug that will be fixed
    let domains = [MPLiveDomainType.occupancy, MPLiveDomainType.temperature, MPLiveDomainType.humidity, MPLiveDomainType.co2, MPLiveDomainType.availability, MPLiveDomainType.count, MPLiveDomainType.position]
    
    override func setupController() async {
    
        for domain in domains {
            mapControl?.enableLiveData(domain: domain) { liveUpdate in
                print("Received live update for domain \(domain): \(liveUpdate)")
                if let liveData = liveUpdate.getLiveValueForKey(domain) as? Int {
                    print("The live data is for \(liveData)")
                }
            }
        }
    }
}
