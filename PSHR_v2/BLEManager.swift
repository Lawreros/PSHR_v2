//
//  BLEManager.swift
//  PSHR_v2
//
//  Created by Ross on 2/7/22.
//

import Foundation
import CoreBluetooth

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    var myCentral: CBCentralManager!
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    
}
