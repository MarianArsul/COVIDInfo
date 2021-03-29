//
//  TabBar.swift
//  CoronaVirus
//
//  Created by Milovan on 05.03.2021.
//

import SwiftUI

struct TabBar: View {

    init() {
        UITabBar.appearance().backgroundColor = .red
        
    }
    
    @State var currentIndex = 0
    
    let tabBarIconsNotFilled = ["house", "arrow.up.forward.circle","bandage"]
    let tabBarIconsFilled = ["house.fill", "arrow.up.forward.circle.fill", "bandage.fill"]
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch currentIndex {
                case 0:
                    HomeView()
                case 1:
                    StatisticsView()
                default:
                    VactinationView()
                }
            }
            
            Divider()
                .padding(.bottom, 15)
            
            HStack {
                ForEach(0..<3){ num in
                    Spacer()
                    Button(action: {
                        currentIndex = num
                    }, label: {
                        Spacer()
                        if currentIndex == num {
                            Image(systemName: tabBarIconsFilled[num])
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(currentIndex == num ? Color(.black) : .init(white: 0.8))
                        }
                        else{
                            Image(systemName: tabBarIconsNotFilled[num])
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(currentIndex == num ? Color(.yellow) : .init(white: 0.8))
                        }
                        Spacer()
                    })
                }
            }
        }
    }
}

struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBar()
    }
}
