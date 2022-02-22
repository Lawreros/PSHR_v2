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
    @Published var datpack: Array<String> = ["n/a","n/a","n/a","n/a","n/a"]
    
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
    
    func onHeartRateReceived(_ heartRate: Array<Float>) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSSS"
        let timestamp = formatter.string(from: Date())
        print("BPM: \(heartRate[0])\t\(heartRate[1])\t\(heartRate[2])\t\(heartRate[3])")
        Logger.log("BPM: \(heartRate[0])\t\(heartRate[1])\t\(heartRate[2])\t\(heartRate[3])", timestamp)
        
        datpack = [timestamp, String(heartRate[0]),String(heartRate[1]),String(heartRate[2]),String(heartRate[3])]
        
//        CurrentTime.text = timestamp
//        heartRateLabel.text = String(heartRate[0])
//        rrInterval1 = String(heartRate[1])
//        rrInterval2 = String(heartRate[2])
//        rrInterval3 = String(heartRate[3])
    }
    
    
}



//MARK: - Text Logger

func getDocumentsDirectory() -> URL {
    //find all possible documents directories for this user
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    
    print(paths)
    
    //just send back the firs one, which ought to be the only one
    return paths[0]
}

class Logger {

    static var TextFile: URL? = {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("failed to find the documentsDirectory")
            return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        let dateString = formatter.string(from: Date())
        let fileName = "\(dateString).txt"
        print(documentsDirectory.appendingPathComponent(fileName))
        return documentsDirectory.appendingPathComponent(fileName)
    }()

    static func log(_ message: String, _ timestamp: String) {
        guard let textFile = TextFile else {
            print("Failed to let textFile=TextFile")
            return
        }
        guard let data = (timestamp + ": " + message + "\n").data(using: String.Encoding.utf8) else { return }

        if FileManager.default.fileExists(atPath: textFile.path) {
            if let fileHandle = try? FileHandle(forWritingTo: textFile) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                print("data successfully written")
                fileHandle.closeFile()
            }
        } else {
            print("try? data.write")
            try? data.write(to: textFile, options: .atomicWrite)
        }
    }
}

//MARK: - Peripheral Functionality

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
            onHeartRateReceived(data)
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid)")
        }
    }
    
    //Deciphers the incomming data into usable numbers
    private func heartRate(from characteristic: CBCharacteristic) -> Array<Float> {
        guard let characteristicData = characteristic.value else {return [-1]}
        let byteArray = [UInt8](characteristicData)
        
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            let size = byteArray.count
            if size == 4{
                return[Float(byteArray[1]),Float(Int(byteArray[3])<<8 + Int(byteArray[2]))/1.024,0,0]
            }
            if size == 6{
                return[Float(byteArray[1]),Float(Int(byteArray[3])<<8 + Int(byteArray[2]))/1.024,Float(Int(byteArray[5])<<8 + Int(byteArray[4]))/1.024,0]
            }
            if size == 8{
                return[Float(byteArray[1]),Float(Int(byteArray[3])<<8 + Int(byteArray[2]))/1.024,Float(Int(byteArray[5])<<8 + Int(byteArray[4]))/1.024,Float(Int(byteArray[7])<<8 + Int(byteArray[6]))/1.024]
            }
            return [0,0,0,0]
        } else {
            // Heart Rate Value Format is in the 2nd and 3rd bytes
            return [(Float(Int(byteArray[1]) << 8)) + Float(Int(byteArray[2])), 23]
        }
    }
    
}
