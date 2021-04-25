//
//  ContentView.swift
//  CoronaVirus
//
//  Created by Milovan on 03.03.2021.
//

import SwiftUI
import PartialSheet

struct ContentView: View {
    
    @EnvironmentObject var partialSheetManager : PartialSheetManager
    
    var body: some View {
        NavigationView {
            Home()
        }
        .addPartialSheet()
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(PartialSheetManager())
    }
}

