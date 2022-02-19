//
//  BLEManager.swift
//  PSHR_v2
//
//  Created by Ross on 2/19/22.
//

import Foundation
import CoreBluetooth

let heartRateServiceCBUUID = CBUUID(string: "0x180D")
let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")


class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    var myCentral: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
    //@Published var isSwitchedOn = false
    //@Published var peripherals = [Peripheral]()
    
        override init() {
            super.init()
     
            myCentral = CBCentralManager(delegate: self, queue: nil)
            myCentral.delegate = self
        }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is unknown")
        case .resetting:
            print("central.state is resetting")
        case .unsupported:
            print("central.state is unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            myCentral.scanForPeripherals(withServices: [heartRateServiceCBUUID])
            print("test if it even gets to here")
        @unknown default:
            print("YIKES! SOMETHING WENT WRONG THAT SHOULDN'T HAVE. I DON'T KNOW WHAT'S GOING ON!")
        }
        
    }
    
    //Activated when the centralManager "didDiscover" a peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        heartRatePeripheral = peripheral
        heartRatePeripheral.delegate = self
        myCentral.stopScan() //TODO: ADD option to select which device you want to connect to before stopping scanning
        myCentral.connect(heartRatePeripheral)
    }
    
    //Activated when the centralManager "didConnect" to the peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        heartRatePeripheral.discoverServices([heartRateServiceCBUUID])
    }
    
}

extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {return}
        for service in services {
            print(service)
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {return}
        
        for characteristic in characteristics {
            print(characteristic)
            
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    //Changed whenever the peripheral updates it's values
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case heartRateMeasurementCharacteristicCBUUID:
            let data = heartRate(from: characteristic)
            //onHeartRateReceived(data)
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    //Deciphers the incomming data into usable numbers
    private func heartRate(from characteristic: CBCharacteristic) -> Array<Float> {
        guard let characteristicData = characteristic.value else {return [-1]}
        print("badump")
        return [0,0,0,0]
    }
    
}
