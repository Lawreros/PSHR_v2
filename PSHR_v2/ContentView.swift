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
        Text("Hello, world! This is a test!to")
            .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
