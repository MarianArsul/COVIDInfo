//
//  Home.swift
//  CoronaVirus
//
//  Created by Milovan on 24.04.2021.
//

import SwiftUI
import SwiftUITrackableScrollView
import PartialSheet


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

let screen: CGRect = UIScreen.main.bounds

struct Home: View {
    @State private var cards = cardsData
    @EnvironmentObject var partialSheetManager : PartialSheetManager
    
    @State var showPreventie = false
    @State var showSimptome = false
    @State var showIntrebariFrecvente = false
    @State var showDocumente = false
    @State var showSympthomsForm = false
    @State var showVaccinare = false
    
    var body: some View {
        if showIntrebariFrecvente == false{
            ScrollView(.vertical, showsIndicators: false) {
                
                HStack {
                    Text(timeOfDay() + "Milovan")
                        .foregroundColor(Color.black)
                        .font(.system(size: 20, weight: .bold))
                        .padding(.leading, 16)
                    
                    Spacer()
                }
                .offset(y: 140)
                
                VStack{
                    HStack {
                        Spacer()
                        
                        Image(systemName: "gear")
                            .font(.system(size: 25, weight: .bold))
                    }
                    .offset(y: -20)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    
                    Button(action: {showSympthomsForm.toggle()}) {
                        ZStack{
                            Image("covid1")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .offset(x: 90)
                                .frame(width:180, height: 180)
                            
                            Text("Ar trebui să mă")
                                .foregroundColor(Color.black)
                                .font(.system(size: 20, weight: .bold))
                                .offset(x: -90)
                                .offset(y: -40)
                            
                            Text("îngrijorez ?")
                                .foregroundColor(Color.black)
                                .font(.system(size: 25, weight: .bold))
                                .offset(x: -96)
                                .offset(y: -14)
                            
                            HStack{
                                Text("Verifică simptomele")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                    .font(.system(size: 15, weight: .bold))
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .offset(x: -74)
                            .offset(y: 20)
                            
                        }
                        .frame(width: 350, height: 250)
                        .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .offset(y: 10)
                    }
                    .sheet(isPresented: $showSympthomsForm){SympthomsTest()}
                    
                    VStack {
                        Text("INFORMAȚII")
                            .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                            .font(.system(size: 15, weight: .bold))
                            .offset(x: -130)
                            //.offset(y: 10)
                        
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack(spacing: 20){
                                Button(action: {self.showPreventie.toggle()}){CardsView(card: cards[0]).offset(x: 30)}.sheet(isPresented: $showPreventie){PreventieView().zIndex(1)}
                                Button(action: {self.showSimptome.toggle()}){CardsView(card: cards[1]).offset(x: 30)}.sheet(isPresented: $showSimptome){SimptomeView()}
                                Button(action: {self.showIntrebariFrecvente.toggle()}){CardsView(card: cards[2]).offset(x: 30)}//.sheet(isPresented: $showIntrebariFrecvente){IntrebariFrecvente().zIndex(1)}
                                Button(action: {self.showDocumente.toggle()}){CardsView(card: cards[3]).offset(x: 30)}.sheet(isPresented: $showDocumente){DocumentsView()}
                                
                                Spacer()
                                Spacer()
                            }
                            .offset(x: -10)
                        }
                    }
                    .offset(y: 15)
                    
                    VStack{
                        HStack {
                            Text("ULTIMELE STATISTICI")
                                .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                                .font(.system(size: 15, weight: .bold))
                                //.offset(x: -95)
                            
                            Spacer()
                            
                            Button(action: {showVaccinare.toggle()}) {
                                HStack {
                                    Text("VEZI MAI MULT")
                                        .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))                           .font(.system(size: 15, weight: .bold))
                                   
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .fullScreenCover(isPresented: $showVaccinare){VactinationView()}
                        }
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        
                        StatisticiPreview()
                    }
                    .offset(y: 40)
                    
                    ZStack{
                        Image("VaccinePreview")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .offset(x: 100)
                            .frame(width: 200, height: 200)
                        
                        Text("Hai la")
                            .font(.system(size: 20, weight: .bold))
                            .offset(x: -130)
                            .offset(y: -40)
                        
                        Text("VACCINARE!")
                            .font(.system(size: 25, weight: .bold))
                            .offset(x: -80)
                            .offset(y: -10)
                        
                        HStack{
                            Text("Găsește un centru")
                                .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                .font(.system(size: 15, weight: .bold))
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                .font(.system(size: 15, weight: .bold))
                        }
                        .offset(x: -74)
                        .offset(y: 20)
                        
                        Text("#OmCuOmOprimPandemia")
                            .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                            .font(.system(size: 13, weight: .bold))
                            .offset(x: -68)
                            .offset(y: 105)
                        
                    }
                    .frame(width: 350, height: 250)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .offset(y: 60)
                    
                    SurseSigure()
                        .offset(y: 50)
                    
                    ForEach(0..<20){item in
                        Spacer()
                    }
                    
                }
                .offset(y: 110)
            }
            .frame(height: screen.height)
            .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitle("Acasă")
            .navigationViewStyle(StackNavigationViewStyle())
        }
        else{
            IntrebariFrecvente()
        }
    }
}

struct StatisticiPreview : View{
    var body: some View{
        
        HStack{
            ZStack{
                Text("Cazuri noi")
                    .font(.system(size: 15, weight: .bold))
                    .offset(y: -50)
                    .offset(x: -30)
                
                Text("###.###")
                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                    .font(.system(size: 20, weight: .bold))
                    .offset(x: -25)
                    .offset(y: -20)
                
                Image("StatisticiPreview")
                    .resizable()
                    .frame(width: 100, height: 50)
                    .aspectRatio(contentMode: .fit)
                    .offset(y: 30)
                
            }
            .frame(width: 160, height: 150)
            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
            
            Spacer()
            
            ZStack{
                Text("Cazuri totale")
                    .font(.system(size: 15, weight: .bold))
                    .offset(y: -50)
                    .offset(x: -20)
                
                Text("#.###.###")
                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                    .font(.system(size: 20, weight: .bold))
                    .offset(x: -17)
                    .offset(y: -20)
                
                Image("StatisticiPreview")
                    .resizable()
                    .frame(width: 100, height: 50)
                    .aspectRatio(contentMode: .fit)
                    .offset(y: 30)
            }
            .frame(width: 160, height: 150)
            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
    }
}

struct SurseSigure : View{
    var body : some View{
        ZStack {
            HStack{
                HStack {
                    Text("SURSE SIGURE DE INFORMARE")
                        .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                        .font(.system(size: 15, weight: .bold))
                    
                    Spacer()
                }
                .padding(.leading, 30)
            }
            .frame(width: screen.width)
            .offset(y: -60)
            
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: -10){
                    ForEach(0..<surseOficiale.count){item in
                        Link(destination: URL(string: surseOficiale[item].website)!){
                            ZStack(alignment: .center){
                                VStack {
                                    surseOficiale[item].image
                                        .resizable()
                                        .frame(width: 70, height: 70)
                                        .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                                    }
                                    .frame(width: 90, height: 190)
                                    .background(Circle().fill(Color.white))
                                    
                                    
                                Text(surseOficiale[item].nume)
                                    .foregroundColor(Color.black)
                                    .offset(y: 80)
                                    //.position(x: 50, y: 20)
                            }
                            .frame(width: 120, height: 250)
                            
                        }
                    }
                }
                .offset(y: 5)
                .offset(x: -10)
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

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            Home()
        }
        .addPartialSheet()
        .navigationViewStyle(StackNavigationViewStyle())
        .environmentObject(PartialSheetManager())
    }
}
