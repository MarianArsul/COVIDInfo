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
    
    let tabBarIconsNotFilled = ["house", "newspaper", "arrow.up.forward.circle","questionmark.circle"]
    let tabBarIconsFilled = ["house.fill", "newspaper.fill", "arrow.up.forward.circle.fill", "questionmark.circle.fill"]
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                switch currentIndex {
                case 0:
                    HomeView()
                case 1:
                    NewsView()
                case 2:
                    StatisticsView()
                default:
                    MythBustersView()
                }
            }
            
            Divider()
                .padding(.bottom, 15)
            
            HStack {
                ForEach(0..<4){ num in
                    Spacer()
                    Button(action: {
                        currentIndex = num
                    }, label: {
                        Spacer()
                        if currentIndex == num {
                            Image(systemName: tabBarIconsFilled[num])
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(currentIndex == num ? Color(.yellow) : .init(white: 0.8))
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
 
