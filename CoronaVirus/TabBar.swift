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
    
    @State var index = 0
    
    var body: some View {
        ZStack {
            VStack{
                switch index{
                case 0:
                    Home()
                case 1:
                    StatisticsView()
                default:
                    VactinationView()
                }
            }
            .frame(width: screen.width, height: 775)
            .background(Color.black)
            .offset(y: -20)
            .zIndex(1)
            
            HStack{
                Button(action: {self.index = 0}){
                    Image(systemName:(index == 0) ? "house.fill" : "house")
                        .foregroundColor((index==0) ? Color(#colorLiteral(red: 0.8805052638, green: 0.3253605962, blue: 0.3551793694, alpha: 1)) : Color.black)
                        .font(.system(size: 25, weight: .bold))
                        .padding(.leading, 50)
                        .offset(y: -10)
                }
                
                
                Spacer()
                
                Button(action: {self.index = 1}){
                    Image(systemName:(index == 1) ? "arrow.up.forward.circle.fill" : "arrow.up.forward.circle")
                        .foregroundColor((index==1) ? Color(#colorLiteral(red: 0.8805052638, green: 0.3253605962, blue: 0.3551793694, alpha: 1)) : Color.black)
                        .font(.system(size: 25, weight: .bold))
                        .offset(y: -10)
                }
                
                Spacer()
                
                Button(action: {self.index = 2}){
                    Image(systemName:(index == 2) ? "bandage.fill" : "bandage")
                        .foregroundColor((index==2) ? Color(#colorLiteral(red: 0.8805052638, green: 0.3253605962, blue: 0.3551793694, alpha: 1)) : Color.black)
                        .font(.system(size: 25, weight: .bold))
                        .padding(.trailing, 50)
                        .offset(y: -10)
                }

            }
            .frame(width: screen.width, height: 100)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
            .offset(y: 380)
            .zIndex(2)
            .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
            
        }
    }
}

struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        TabBar()
    }
}
