//
//  StatisticsView.swift
//  CoronaVirus
//
//  Created by Milovan on 05.03.2021.
//

import SwiftUI

struct StatisticsView: View {
    
    @State var showLocationSettings = false
    
    var body: some View {
        NavigationView(){
            ScrollView(.vertical, showsIndicators: false){
                Divider()
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 10){
                        QuickStatCards(link: "https://datelazi.ro/embed/confirmed_cases", title: "Cazuri confimate", actualizare: "15 mai 2021")
                        QuickStatCards(link: "https://datelazi.ro/embed/cured_cases", title: "Vindecați", actualizare: "15 mai 2021")
                        QuickStatCards(link: "https://datelazi.ro/embed/dead_cases", title: "Decedați", actualizare: "15 mai 2021")
                        
                        ForEach(0..<2){item in
                            Spacer()
                        }
                    }
                    .offset(x: 16)
                    .frame(height: 290)
                }
                .offset(y: -30)
                
                VStack{
                    extendedStats(link: "https://datelazi.ro/embed/cazuri-pe-zi", title: "Cazuri pe zi", actualizare: "15 mai 2021", cardHeight: 680)
                    
                    extendedStats(link: "https://datelazi.ro/embed/categorie-varsta", title: "Cazuri per categorie de vârstă, în timp", actualizare: "15 mai 2021", cardHeight: 710)
                    
                    ZStack{
                        VStack{
                            HStack {
                                Text("Incidența la nivel județean")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 25, weight: .bold))
                                
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .offset(y: 10)
                            
                            HStack {
                                Text("Ultima actualizare: 15 mai 2021")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color.black)
                                
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .offset(y: 10)
                        }
                        .frame(width: 360, height: 100)
                        .background(VisualEffectBlur())
                        .clipShape(RoundedCorners(tl: 20, tr: 20, bl: 0, br: 0))
                        .offset(y: -220)
                        .zIndex(2)
                        
                        
                        Webview(url: URL(string: "https://datelazi.ro/embed/counties-map")!)
                            .frame(width: 370, height: 550)
                    }
                    .frame(width: 360, height: 540)
                    .background(VisualEffectBlur())
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 20)
                    
                    ZStack{
                        VStack{
                            HStack {
                                Text("Incidența la nivel județean")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 25, weight: .bold))
                                
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .offset(y: 10)
                            
                            HStack {
                                Text("Ultima actualizare: 15 mai 2021")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color.black)
                                
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .offset(y: 10)
                        }
                        .frame(width: 360, height: 100)
                        .background(VisualEffectBlur())
                        .clipShape(RoundedCorners(tl: 20, tr: 20, bl: 0, br: 0))
                        .offset(y: -220)
                        .zIndex(2)
                        
                        
                        Webview(url: URL(string: "https://datelazi.ro/embed/counties-table")!)
                            .frame(width: 370, height: 550)
                    }
                    .frame(width: 360, height: 540)
                    .background(VisualEffectBlur())
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 20)
                    
                    ZStack{
                        VStack{
                            HStack {
                                Text("Cazuri după vârstă")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 25, weight: .bold))
                                
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .offset(y: 10)
                            
                            HStack {
                                Text("Ultima actualizare: 15 mai 2021")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(Color.black)
                                
                                Spacer()
                            }
                            .padding(.leading, 20)
                            .offset(y: 10)
                        }
                        .frame(width: 360, height: 89)
                        .background(VisualEffectBlur())
                        .clipShape(RoundedCorners(tl: 20, tr: 20, bl: 0, br: 0))
                        .offset(y: -150)
                        .zIndex(2)
                        
                        
                        Webview(url: URL(string: "https://datelazi.ro/embed/varsta")!)
                            .frame(width: 370, height: 400)
                    }
                    .frame(width: 360, height: 390)
                    .background(VisualEffectBlur())
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                    .padding(.bottom, 20)
                }
                .offset(y: -40)
            }
            .navigationBarTitle(Text("Statistici"))
        }
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
    }
}
