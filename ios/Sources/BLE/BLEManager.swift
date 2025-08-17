import Foundation
import CoreBluetooth
import Combine

final class BLEManager: NSObject, ObservableObject {
    @Published var isScanning: Bool = false
    @Published var isConnected: Bool = false

    private var central: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var alertCharacteristic: CBCharacteristic?

    private let serviceUUID = CBUUID(string: "1811") // Alert Notification Service
    private let newAlertUUID = CBUUID(string: "2A46") // New Alert characteristic

    override init() {
        super.init()
        central = CBCentralManager(delegate: self, queue: .main)
    }

    func start() {
        if central.state == .poweredOn { startScan() }
    }

    func restartScan() {
        disconnect()
        startScan()
    }

    private func startScan() {
        guard central.state == .poweredOn else { return }
        isScanning = true
        let options: [String: Any] = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        central.scanForPeripherals(withServices: [serviceUUID], options: options)
    }

    private func stopScan() {
        central.stopScan()
        isScanning = false
    }

    private func disconnect() {
        if let p = peripheral {
            central.cancelPeripheralConnection(p)
        }
        peripheral = nil
        alertCharacteristic = nil
        isConnected = false
    }
}

extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            startScan()
        } else {
            isScanning = false
            isConnected = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? ""
        if name == "SafetyRing" {
            stopScan()
            self.peripheral = peripheral
            peripheral.delegate = self
            central.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        startScan()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        startScan()
    }
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil else { return }
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == serviceUUID {
            peripheral.discoverCharacteristics([newAlertUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else { return }
        guard let chars = service.characteristics else { return }
        for ch in chars where ch.uuid == newAlertUUID {
            alertCharacteristic = ch
            peripheral.setNotifyValue(true, for: ch)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else { return }
        guard let data = characteristic.value else { return }
        if let text = String(data: data, encoding: .utf8), text.uppercased().contains("ALERT") {
            NotificationCenter.default.post(name: AlertHandler.alertNotificationName, object: nil)
        }
    }
}


