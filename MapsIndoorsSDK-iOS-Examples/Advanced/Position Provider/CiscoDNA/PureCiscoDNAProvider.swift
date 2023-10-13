//
//  PureCiscoDNAProvider.swift
//  Demos
//
//  Created by Christian Wolf Johannsen on 19/06/2023.
//

import MapsIndoorsCore
import MapsIndoors
import OSLog

class PureCiscoDNAProvider: NSObject, MPPositionProvider {
    var tenantId: String? = nil

    private var ciscoRunning = false
    private var ciscoUpdateAge: Double = 0
    private var ciscoDeviceId: String? {
        didSet {
            if oldValue != ciscoDeviceId && ciscoDeviceId != nil {
                updateDeviceLocationFromCisco()
                connectToMQTT()
            }
        }
    }
    private var lastCiscoPositionTimestamp: Date?
    private lazy var mqttClient = MPMQTTSubscriptionClient() // TODO: create public Swift interface
    private lazy var dnaLogger = Logger(subsystem: "com.mapspeople", category: "CiscoDNA")
   
    // Instance variables to store the IPs
    private var _lanIPAddress: String?
    private var _wanIPAddress: String?

    // MARK: - MPPositionProvider protocol compliance
    var delegate: MPPositionProviderDelegate?
    var latestPosition: MPPositionResult?
    var locationServicesActive = true
    var preferAlwaysLocationPermission = false
    //var providerType: MPPositionProviderType = .WIFI_POSITION_PROVIDER

    func startPositioning(_ arg: String?) {
        guard isRunning() == false else { return }

        refreshDeviceInfo()
        ciscoRunning = true
    }

    func stopPositioning(_ arg: String?) {
        guard isRunning() == true else { return }

        mqttClient.disconnect()
        ciscoRunning = false
    }

    func requestLocationPermissions() {
        // Empty on purpose
    }

    func updateLocationPermissionStatus() {
        // Empty on purpose
    }

    func startPositioning(after millis: Int32, arg: String?) {
        // Empty on purpose
    }

    func isRunning() -> Bool {
        ciscoRunning
    }


    // MARK: - Cisco DNA Implementation
    private func fetchWANIPAddress(completion: @escaping () -> Void) {
        guard let url = URL(string: "https://ipinfo.io/ip") else {
            completion()
            return
        }

        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data, let wanIP = String(data: data, encoding: .utf8) {
                self._wanIPAddress = wanIP
            }
            completion()
        }

        task.resume()
    }
    
    private func refreshDeviceInfo() {
        if _lanIPAddress == nil {
            _lanIPAddress = UIDevice.current.getIP()
            dnaLogger.debug("\(#function): \(self._lanIPAddress ?? "")")
        }
        
        if _wanIPAddress == nil {
            fetchWANIPAddress {
                if self._lanIPAddress != nil && self._wanIPAddress != nil {
                    self.updateDeviceID()
                }
                self.dnaLogger.debug("\(self.debugDescription)")
            }
        } else {
            if _lanIPAddress != nil {
                updateDeviceID()
            }
            dnaLogger.debug("\(self.debugDescription)")
        }
    }

    private func updateDeviceID() {
        dnaLogger.debug("Refreshing device ID. Current: \(self.ciscoDeviceId ?? "nil")")
        
        guard let tenId = tenantId, let lanIP = _lanIPAddress, let wanIP = _wanIPAddress else { return }
        
        let urlString = "https://ciscodna.mapsindoors.com/\(tenId)/api/ciscodna/devicelookup?clientIP=\(lanIP)&wanIp=\(wanIP)"
        guard let url = URL(string: urlString) else { return }

        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            do {
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    self.dnaLogger.debug("\(#function) - HTTP status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    self.ciscoDeviceId = "device-oABFkvpzCiFrr3A5gd0O"
                    return
                }
                if let data = data, let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let deviceId = json["deviceId"] as? String {
                        self.ciscoDeviceId = deviceId
                    }
                }
            } catch {
                // contents could not be loaded
                return
            }
            self.dnaLogger.debug("\(self.debugDescription)")
        }
        dataTask.resume()
    }

    private func updateDeviceLocationFromCisco() {
        guard let tenId = tenantId, let deviceId = ciscoDeviceId else { return }
        
        let urlString = "https://ciscodna.mapsindoors.com/\(tenId)/api/ciscodna/\(deviceId)"
        guard let url = URL(string: urlString) else { return }

        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    self.dnaLogger.debug("\(#function) - HTTP status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    return
                }
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    let positionResult = try decoder.decode(MPPositionResult.self, from: data)
                    self.evaluateDeviceLocationFromCisco(positionResult)
                } catch {
                    self.dnaLogger.debug("\(#function) - Decoding error: \(error)")
                }
            }
        }
        dataTask.resume()
    }

    private func evaluateDeviceLocationFromCisco(_ positionResult: MPPositionResult?) {
        guard let posRes = positionResult else { return }

        //if let updateAge = posRes.properties?["age"] as? Double {
            ciscoUpdateAge += ciscoUpdateAge
            lastCiscoPositionTimestamp = Date().addingTimeInterval(-ciscoUpdateAge)
            notifyNewPosition(positionResult: posRes)
        //}
        dnaLogger.debug("Device Location: latitude=\(posRes.coordinate.latitude), longitude=\(posRes.coordinate.longitude), \(posRes.floorIndex)")
    }

    private func notifyNewPosition(positionResult: MPPositionResult) {
        guard isRunning() == true else { return }

        latestPosition = positionResult
        //latestPosition?.provider = self

        if let deleg = delegate {
            deleg.onPositionUpdate(position: latestPosition!)
        }
    }

    private func connectToMQTT() {
        mqttClient.delegate = self
        if mqttClient.state != .connected {
            mqttClient.connect(true)
        } else {
            subscribeToCiscoDNAPositioning()
        }
    }

    private func subscribeToCiscoDNAPositioning() {
        guard let tenId = tenantId, let deviceId = ciscoDeviceId else { return }

        let topic = MPCiscoPositionTopic(tenantId: tenId, deviceId: deviceId)
        mqttClient.subscribe(topic)
    }

    // MARK: Debug Info
    override var debugDescription: String {
        return [
            "LAN IP: \(_lanIPAddress ?? "?")",
            "WAN IP: \(_wanIPAddress ?? "?")",
            "Age: \(ciscoUpdateAge)",
            "Request time: \(lastCiscoPositionTimestamp?.description ?? "?")"
        ].joined(separator: "\n")
    }
}

// MARK: - MPSubscriptionClientDelegate
extension PureCiscoDNAProvider: MPSubscriptionClientDelegate {
    func didReceiveMessage(_ message: Data, onTopic topicString: String) {
        
        let data = message
        do {
            let decoder = JSONDecoder()
            let positionResult = try decoder.decode(MPPositionResult.self, from: data)
            self.evaluateDeviceLocationFromCisco(positionResult)
        } catch {
            self.dnaLogger.debug("\(#function) - Decoding error: \(error)")
        }
    }

    func didUpdateState(_ state: MPSubscriptionState) {
        if state == .connected {
            if ciscoDeviceId != nil {
                subscribeToCiscoDNAPositioning()
            } else {
                refreshDeviceInfo()
            }
        }
    }

    func didSubscribe(_ topic: MPSubscriptionTopic) {
        dnaLogger.debug("Subscribed to \(topic.topicString)")
    }

    func didUnsubscribe(_ topic: MPSubscriptionTopic) {
        dnaLogger.debug("Unsubscribed from \(topic.topicString)")
    }

    func onSubscriptionError(_ error: Error, topic: MPSubscriptionTopic) {
        refreshDeviceInfo()
    }

    func onUnsubscriptionError(_ error: Error, topic: MPSubscriptionTopic) {
        // Empty on purpose
    }

    func onError(_ error: Error) {
        refreshDeviceInfo()
    }
}

// MARK: - Helper methods
extension UIDevice {
    /**
     Returns device ip address. Nil if connected via cellular.
     */
    func getIP() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }

                guard let interface = ptr?.pointee else { return nil }

                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {

                    guard let ifa_name = interface.ifa_name else { return nil }

                    let name: String = String(cString: ifa_name)

                    if name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }

        return address
    }
}

class MPCiscoPositionTopic: MPSubscriptionTopic {

    private var deviceId: String
    private var tenantId: String

    init(tenantId: String, deviceId: String) {
        self.deviceId = deviceId
        self.tenantId = tenantId
    }

    required init(topic: String) {
        let comps = topic.split(separator: "/")
        self.tenantId = String(comps[1])
        self.deviceId = String(comps[2])
    }

    var topicString: String {
        return "ciscodna/\(tenantId)/\(deviceId)/position"
    }
}
