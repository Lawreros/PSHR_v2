//
//  ContentView.swift
//  PSHR_v2
//
//  Created by Ross on 1/29/22.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var bleManager = BLEManager()
    
    var body: some View {
        //Text("Hello, world! This is a test!to")
//        .padding
        HStack{
            Text(bleManager.datpack[0])
            Text(bleManager.datpack[1])
            Text(bleManager.datpack[2])
            Text(bleManager.datpack[3])
            Text(bleManager.datpack[4])
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
