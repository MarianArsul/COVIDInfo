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
    @State var tabIndex:Int = 0
    
    var body: some View {
        TabView(selection: $tabIndex) {
            Home2_0().tabItem { Group{
                Image(systemName: tabIndex == 0 ?  "house":"house.fill")
                    Text("Acasa")
                }}.tag(0)
            StatisticsView().tabItem { Group{
                Image(systemName: tabIndex == 1 ?  "arrow.up.forward.circle":"arrow.up.forward.circle.fill")
                    Text("Statistici")
                }}.tag(1)
            Vaccinare2_0().tabItem { Group{
                Image(systemName: tabIndex == 2 ? "staroflife" : "staroflife.fill")
                    Text("Vaccinare")
                }}.tag(2)
        }
    }
}

struct ContentViewPreviews: PreviewProvider {
    static var previews: some View{
        ContentView()
    }
}


let tabBarIconsFilled = ["house.fill", "arrow.up.forward.circle.fill", "staroflife.fill"]

