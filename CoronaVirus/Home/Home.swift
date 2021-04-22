//
//  Home.swift
//  CoronaVirus
//
//  Created by Milovan on 11.04.2021.
//

import SwiftUI
import SwiftUITrackableScrollView

//function used to display message based on time of day
func timeOfDay() -> String {
    let hour = Calendar.current.component(.hour, from: Date()) // get current hour
    var messageToBeDisplayed = ""
    //depending on var hour, switch to the appropiate greeting
    switch hour {
        case 6..<12 : messageToBeDisplayed = "Bună dimineața, "
        case 12..<18 : messageToBeDisplayed = "Bună ziua, "
        default: messageToBeDisplayed = "Bună seara, "
        }
    return messageToBeDisplayed
}

struct Home: View {
    
    @State private var scrollViewContentOffset = CGFloat(0)
    @State var cards = cardsData
    @State var articles = articleData
    @State var viewState = CGSize.zero
    
    @State var showPreventie = false
    @State var showSimptome = false
    @State var showIntrebariFrecvente = false
    @State var showDocumente = false
    @State var showSettings = false
    @State public var showNews = false
    
    var body: some View {
        ScrollView {
            ZStack{
                ZStack{
                    Text("Acasă")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(Color.white)
                        .offset(y: 25)
                        .opacity(scrollViewContentOffset > 60 ? 0.01 * Double(scrollViewContentOffset) : 0)
                    
                    Button(action: {self.showSettings.toggle()}){
                        HStack {
                            Image(systemName: "gear")
                                .font(.system(size: 25, weight: .bold))
                                .foregroundColor(Color.black)
                        }
                        .background(Circle().fill(Color.white))
                        .offset(x: 150)
                        .offset(y: 25)
                    }
                }
                .frame(width: showNews ? 0 : screen.width, height: showNews ? 0 : 100)
                .background(Color.black)
                .offset(y: -390)
                .zIndex(2)
                
                TrackableScrollView(.vertical, showIndicators: false, contentOffset: $scrollViewContentOffset){
                    
                    Text(timeOfDay())
                        .foregroundColor(Color.white)
                        .offset(y: 100)
                        .font(.system(size: 35, weight: .bold))
                        .offset(x: -80)
                    
                    Text("Milovan")
                        .foregroundColor(Color(#colorLiteral(red: 0.8805052638, green: 0.3253605962, blue: 0.3551793694, alpha: 1)))
                        .font(.system(size: 35, weight: .bold))
                        .offset(y: 94)
                        .offset(x: -103)
                    
                    /*HStack{
                        Text("Acasă")
                            .underline()
                            .foregroundColor(Color(#colorLiteral(red: 0.9004377723, green: 0.3697259426, blue: 0.2659708261, alpha: 1)))
                            .padding(.leading, 30)
                            .font(.system(size: 20, weight: .bold))
                        
                        Spacer()
                        
                        Text("Statistici")
                            .foregroundColor(Color.white)
                            .font(.system(size: 20, weight: .bold))
                        
                        Spacer()
                        
                        Text("Vaccinare")
                            .foregroundColor(Color.white)
                            .padding(.trailing, 30)
                            .font(.system(size: 20, weight: .bold))
                    }
                    .frame(width: screen.width, height: 40)
                    .background(Color.black)
                    .offset(y: 110)*/
                    
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack(spacing: 20){
                            Button(action: {self.showPreventie.toggle()}){CardsView(card: cards[0]).offset(x: 30)}.sheet(isPresented: $showPreventie){PreventieView()}
                            Button(action: {self.showSimptome.toggle()}){CardsView(card: cards[1]).offset(x: 30)}.sheet(isPresented: $showSimptome){SimptomeView()}
                            Button(action: {self.showIntrebariFrecvente.toggle()}){CardsView(card: cards[2]).offset(x: 30)}.sheet(isPresented: $showIntrebariFrecvente){MythBustersView()}
                            Button(action: {self.showDocumente.toggle()}){CardsView(card: cards[3]).offset(x: 30)}.sheet(isPresented: $showDocumente){DocumentsView()}
                            
                            Spacer()
                            Spacer()
                        }
                    }
                    .offset(y: 85)
                    
                    SurseSigure()
                        .offset(y: 100)
                    
                    Text("Stiri")
                        .foregroundColor(Color.white)
                        .font(.system(size: 25, weight: .bold))
                        .offset(y: 120)
                        .offset(x: -140)
                    
                    VStack(spacing: 20){
                        ForEach(articles.indices, id: \.self) { index in
                            GeometryReader { geometry in
                                Button(action: {showNews.toggle()}){
                                    ArticleView(show: self.$articles[index].show, article: self.articles[index])
                                        .zIndex(3)
                                        .offset(y: self.articles[index].show ? -geometry.frame(in: .global).minY : 0)
                                }
                            }
                            .frame(height: self.articles[index].show ? screen.height : 280)
                            .frame(maxWidth: self.articles[index].show ? .infinity : screen.width-60)
                        }
                    }
                    .offset(y: 130)
                    
                    if showSettings == true {
                        SettingsView()
                            .background(Color.black.opacity(0.001))
                            .offset(y: showSettings ? 0:100)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0))
                            .onTapGesture {
                                self.showSettings.toggle()
                            }
                            .gesture(
                                DragGesture().onChanged {value in self.viewState = value.translation}
                                .onEnded{value in
                                    if self.viewState.height > 50 {
                                        self.showSettings = false
                                    }
                                    self.viewState = .zero
                            }
                        )
                    }
                }
                .zIndex(1)
                
            }
            .frame(width: screen.width, height: screen.height)
            .background(Color.black)
        }
        //.padding(.top, 4)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .offset(y: showSettings ? -400:0)
        .offset(y: viewState.height)
        .rotation3DEffect(Angle(degrees: showSettings ? Double(viewState.height / 10) - 10 : 0), axis: (x: 10, y: 0, z: 0.0))
        .shadow(color: showSettings ? Color.black.opacity(4) : Color.white, radius: showSettings ? 20 : 0, x:0, y:20)
        .scaleEffect(showSettings ? 0.9:1)
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0))
        .edgesIgnoringSafeArea(.all)
    }
}

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}

struct SurseSigure : View{
    var body : some View{
        ZStack {
            HStack{
                HStack {
                    Text("Surse ")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundColor(Color.white)
                    + Text("sigure")
                        .foregroundColor(Color(#colorLiteral(red: 0.8805052638, green: 0.3253605962, blue: 0.3551793694, alpha: 1)))
                        .font(.system(size: 25, weight: .bold))
                    }
                    .padding(.leading, 30)
                
                Spacer()
                
                Link(destination: URL(string: "https://vaccinare-covid.gov.ro/resurse/surse-oficiale-de-informare/")!){
                    Image(systemName: "info.circle")
                        .foregroundColor(Color.white)
                        .font(.system(size: 25, weight: .bold))
                        .padding(.trailing, 30)
                }
            }
            .frame(width: screen.width)
            .offset(y: -60)
            
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: 10){
                    ForEach(0..<surseOficiale.count){item in
                        Link(destination: URL(string: surseOficiale[item].website)!){
                            VStack(alignment: .center){
                                surseOficiale[item].image
                                    .resizable()
                                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                                    .frame(width: 60, height: 60)
                                    .position(x: 50, y: 55)
                                
                                Text(surseOficiale[item].nume)
                                    .foregroundColor(Color.white)
                                    .position(x: 50, y: 20)
                            }
                            .frame(width: 90, height: 190)
                        }
                    }
                    
                    Spacer()
                    Spacer()
                }
                .offset(y: 40)
            }
            .offset(x: 20)
            .offset(y: 10)
        }
        .frame(width: screen.width, height: 190)
    }
}

struct Sursa : Identifiable {
    var id = UUID()
    var nume: String
    var website: String
    var websitePrint: String
    var image: Image
    var color: Color
}

let surseOficiale = [
    Sursa(nume: "Evoluția COVID-19", website: "https://datelazi.ro/", websitePrint: "www.datelazi.ro", image: Image("datelazi"), color: Color(#colorLiteral(red: 0.9383168221, green: 0.737329185, blue: 0.837926209, alpha: 1))),
    Sursa(nume: "Știri oficiale", website: "https://stirioficiale.ro/informatii", websitePrint: "www.stirioficiale.ro", image: Image("stirioficiale"), color: Color(#colorLiteral(red: 0.4577399492, green: 0.8484248519, blue: 0.7813860774, alpha: 1))),
    Sursa(nume: "Ministerul Sănătății", website: "http://www.ms.ro", websitePrint: "www.ms.ro", image: Image("ms"), color: Color(#colorLiteral(red: 0.05995995551, green: 0.2982606888, blue: 0.5433130264, alpha: 1))),
    Sursa(nume: "ECDC", website: "https://www.ecdc.europa.eu/en", websitePrint: "www.ecdc.europa.eu", image: Image("ecdc"), color: Color(#colorLiteral(red: 0.5605708957, green: 0.7272414565, blue: 0.1362667084, alpha: 1))),
    Sursa(nume: "Consiliul Europei", website: "https://ec.europa.eu/info/live-work-travel-eu/coronavirus-response/safe-covid-19-vaccines-europeans_ro", websitePrint: "www.ec.europa.eu", image: Image("eu"), color: Color(#colorLiteral(red: 0.147555232, green: 0.2898129225, blue: 0.6446350217, alpha: 1))),
    Sursa(nume: "AEM", website: "https://www.ema.europa.eu/en", websitePrint: "www.ema.europa.eu", image: Image("ema"), color: Color(#colorLiteral(red: 0.05977845937, green: 0.2519665956, blue: 0.5820891857, alpha: 1))),
    Sursa(nume: "OMS", website: "https://who.int", websitePrint: "www.who.int", image: Image("who"), color: Color(#colorLiteral(red: 0.1968083084, green: 0.5436140895, blue: 0.8174911141, alpha: 1)))
    /*Sursa(nume: "Conduită sanitară", website: "https://stirioficiale.ro/conduita", image: Image("placeholder")),
    Sursa(nume: "Conduită sanitară", website: "https://stirioficiale.ro/conduita", image: Image("placeholder")),
    Sursa(nume: "Conduită sanitară", website: "https://stirioficiale.ro/conduita", image: Image("placeholder")),
    Sursa(nume: "Conduită sanitară", website: "https://stirioficiale.ro/conduita", image: Image("placeholder"))*/
]
