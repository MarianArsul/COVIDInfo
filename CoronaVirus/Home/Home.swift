//
//  Home.swift
//  CoronaVirus
//
//  Created by Milovan on 24.04.2021.
//

import SwiftUI
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
    return messageToBeDisplayed.uppercased()
}

let screen: CGRect = UIScreen.main.bounds
var name: String = "Milovan"
let settingsIcon = Image(systemName: "gear")

struct Home: View {
    @State private var cards = cardsData
    @EnvironmentObject var partialSheetManager : PartialSheetManager
    
    @State var showPreventie = false
    @State var showSimptome = false
    @State var showIntrebariFrecvente = false
    @State var showDocumente = false
    @State var showSympthomsForm = false
    @State var showVaccinare = false
    @State var showSettings = false
    
    var body: some View {
        NavigationView() {
            ZStack {
                if showSettings == true {
                    ZStack {
                        

                        Button(action: {showSettings.toggle()}){
                            Image(systemName: "xmark")
                                .foregroundColor(Color.black)
                                .font(.system(size: 20, weight: .bold))
                        }
                        
                        .offset(y: -130)
                        .offset(x: 130)
                    }
                    .frame(width:screen.width, height: screen.height)
                    .background(Color.black.opacity(0.5))
                    .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                    .zIndex(2)
                }
                
                ScrollView(.vertical, showsIndicators: false) {
                    ScrollViewReader{value in
                        HStack {
                            VStack {
                                
                                
                                if name != ""{
                                    HStack {
                                        Text(timeOfDay() + name)
                                            .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                                            .font(.system(size: 20, weight: .bold))
                                            .offset(y: -6)
                                        
                                        Spacer()
                                    }
                                    .offset(x: 46)
                                }
                            }
                            .offset(x: -30)
                            
                            Spacer()
                            
                            Button(action: {showSettings.toggle()}){
                                Image(systemName: "gear")
                                    .foregroundColor(Color.black)
                                    
                            }
                            .frame(width: 50, height: 50)
                            .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                            .font(.system(size: 30, weight: .bold))
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                            .offset(y: -10)
                        }
                        .offset(y: 15)
                        
                        VStack{
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    Button(action: {showSympthomsForm.toggle()}) {
                                        ZStack{
                                            Image("covid1")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .offset(x: 90)
                                                .frame(width:130, height: 130)
                                            
                                            Text("Ar trebui să mă")
                                                .foregroundColor(Color.black)
                                                .font(.system(size: 18, weight: .bold))
                                                .offset(x: -90)
                                                .offset(y: -40)
                                            
                                            Text("îngrijorez ?")
                                                .foregroundColor(Color.black)
                                                .font(.system(size: 25, weight: .bold))
                                                .offset(x: -90)
                                                .offset(y: -14)
                                            
                                            HStack{
                                                Text("Verifică simptomele")
                                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                                    .font(.system(size: 15, weight: .bold))
                                                
                                                Image(systemName: "arrow.right")
                                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                                    .font(.system(size: 15, weight: .bold))
                                            }
                                            .offset(x: -68)
                                            .offset(y: 20)
                                            
                                        }
                                        .frame(width: 340, height: 200)
                                        .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                                        .padding(.leading, 20)
                                        //.padding(.trailing, 20)
                                        .padding(.top, 10)
                                        .padding(.bottom, 10)
                                        
                                    }
                                    .sheet(isPresented: $showSympthomsForm){Triaj()}
                                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                                    
                                    Button(action: {}) {
                                        ZStack{
                                            Image("VaccinePreview")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .offset(x: 90)
                                                .frame(width:180, height: 180)
                                            
                                            Text("Hai la")
                                                .foregroundColor(Color.black)
                                                .font(.system(size: 20, weight: .bold))
                                                .offset(x: -130)
                                                .offset(y: -40)
                                            
                                            Text("VACCINARE")
                                                .foregroundColor(Color.black)
                                                .font(.system(size: 25, weight: .bold))
                                                .offset(x: -85)
                                                .offset(y: -14)
                                            
                                            HStack{
                                                Text("Gaseste un centru")
                                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                                    .font(.system(size: 15, weight: .bold))
                                                
                                                Image(systemName: "arrow.right")
                                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                                    .font(.system(size: 15, weight: .bold))
                                            }
                                            .offset(x: -74)
                                            .offset(y: 20)
                                            
                                        }
                                        .frame(width: 350, height: 200)
                                        .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                                        //.padding(.leading, 20)
                                        //.padding(.trailing, 20)
                                        .padding(.top, 10)
                                        .padding(.bottom, 10)
                                        
                                    }
                                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                                    
                                    Button(
                                        action: {
                                            withAnimation{value.scrollTo(2)};
                                            self.partialSheetManager.showPartialSheet({})
                                            {Webview(url: URL(string: articleData[0].link)!)}
                                        }
                                        ,label: {
                                            ZStack{
                                                Image(articleData[0].vaccinare ? "news1" : "news2")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .offset(x: 90)
                                                    .frame(width:180, height: 180)
                                                
                                                Text(articleData[0].titlu)
                                                    .foregroundColor(Color.black)
                                                    .font(.system(size: articleData[0].vaccinare ? 17 : 23, weight: .bold)) //23
                                                    .frame(width: 170, height: 200)
                                                    .offset(x: -74)
                                                
                                                HStack{
                                                    Text("Citeste mai mult")
                                                        .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                                        .font(.system(size: 15, weight: .bold))
                                                    
                                                    Image(systemName: "arrow.right")
                                                        .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                                        .font(.system(size: 15, weight: .bold))
                                                }
                                                .offset(x: -82)
                                                .offset(y: 70)
                                                
                                            }
                                            .frame(width: 350, height: 200)
                                            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                                            //.padding(.leading, 20)
                                            .padding(.trailing, 20)
                                            .padding(.top, 10)
                                            .padding(.bottom, 10)
                                       }
                                        
                                    )
                                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                                }
                                .frame(height: 250)
                            }
                            .offset(y: -20)
                            
                            VStack {
                                Text("INFORMAȚII")
                                    .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                                    .font(.system(size: 15, weight: .bold))
                                    .offset(x: -130)
                                    //.offset(y: 10)
                                
                                ScrollView(.horizontal, showsIndicators: false){
                                    HStack(spacing: -10){
                                        Button(action: {self.showPreventie.toggle()}){CardsView(card: cards[0]).offset(x: 30)}.sheet(isPresented: $showPreventie){PreventieView().zIndex(1)}
                                        Button(action: {self.showSimptome.toggle()}){CardsView(card: cards[1]).offset(x: 30)}.sheet(isPresented: $showSimptome){SimptomeView()}
                                        Button(action: {self.showDocumente.toggle()}){CardsView(card: cards[3]).offset(x: 30)}.sheet(isPresented: $showDocumente){DocumentsView()}
                                        
                                        Spacer()
                                        Spacer()
                                    }
                                    .offset(x: -25)
                                    .offset(y: -8)
                                }
                                
                                NavigationLink(destination: IntrebariFrecvente()) {
                                    ZStack(){
                                       Image("intrebariFrecventeCard")
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 350, height: 60)
                                            .accessibility(hidden: true)
                                            .offset(y: -40)
                                        
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text("Intrebari frecvente")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(Color(#colorLiteral(red: 0.1024787799, green: 0.1775858402, blue: 0.2037084699, alpha: 1)))
                                            }
                                            .frame(height: 100)
                                            Spacer()
                                            
                                            Image(systemName: "chevron.forward")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Color(#colorLiteral(red: 0.1024787799, green: 0.1775858402, blue: 0.2037084699, alpha: 1)))
                                        }
                                        .padding()
                                        .accessibilityElement(children: .combine)
                                        .background(VisualEffectBlur())
                                        .frame(height: 60)
                                    }
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                                    .padding()
                                    .accessibilityElement(children: .contain)
                                    .frame(width: 350, height: 60)
                                    .padding(.bottom, 20)
                                }
                                
                            }
                            .offset(y: -30)
                            
                            VStack{
                                HStack {
                                    Text("ULTIMELE STATISTICI")
                                        .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                                        .font(.system(size: 15, weight: .bold))
                                        .offset(x: 5)
                                    
                                    Spacer()
                                    
                                    Button(action: {showVaccinare.toggle()}) {
                                        HStack {
                                            Text("VEZI MAI MULT")
                                                .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                                .font(.system(size: 15, weight: .bold))
                                           
                                            Image(systemName: "arrow.right")
                                                .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                                                .font(.system(size: 15, weight: .bold))
                                        }
                                    }
                                    .fullScreenCover(isPresented: $showVaccinare){VaccinationView()}
                                }
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .offset(y: -20)
                                
                                ScrollView(.horizontal, showsIndicators: false){
                                    HStack(spacing: 10) {
                                        QuickStatCards(link: "https://datelazi.ro/embed/confirmed_cases", title: "Cazuri confimate", actualizare: "15 mai 2021")
                                        QuickStatCards(link: "https://datelazi.ro/embed/total_vaccine", title: "Vaccin-uri administrate", actualizare: "15 mai 2021")
                                        
                                        ForEach(0..<2){item in
                                            Spacer()
                                        }
                                    }
                                    .offset(x: 16)
                                    .frame(height: 340)
                                }
                                .offset(y: -40)
                                
                                
                            }
                            .offset(y: -20)
                            
                            SurseSigure()
                                .padding(.top, 30)
                                .padding(.bottom, 20)
                                .offset(y: -100)
                            
                            VStack{
                                HStack {
                                    Text("ULTIMELE INFORMAȚII OFICIALE")
                                        .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                                        .font(.system(size: 15, weight: .bold))
                                        .padding(.leading, 20)
                                    
                                    Spacer()
                                    
                                    Button(action: {articlePresentedScrape()}){
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                                            .font(.system(size: 15, weight: .bold))
                                            .padding(.trailing, 20)
                                    }
                                }
                                
                                VStack(spacing: -10){
                                    ForEach(0..<articleData.count){item in
                                        Button(
                                            action: {self.partialSheetManager.showPartialSheet({})
                                                {Webview(url: URL(string: articleData[item].link + "#article")!)}
                                            }
                                            ,label: {
                                                News(article: articleData[item])}
                                        )
                                        .id(item)
                                    }
                                }
                                
                            }
                            .offset(y: -100)
                        }
                        ForEach(0..<20){item in
                            Spacer()
                        }
                    }
                }
                .offset(y: 52)
            }
            .frame(width: screen.width, height: screen.height)
            .navigationBarTitle(Text("Acasă"))
        }
        .frame(width: screen.width-10, height:screen.height)
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
        .zIndex(1)
    }
}

struct SurseSigure : View{
    
    @EnvironmentObject var partialSheetManager : PartialSheetManager
    
    var body : some View{
        VStack {
            Text("SURSE SIGURE")
                .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                .font(.system(size: 15, weight: .bold))
                .offset(x: -120)
            
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: 10){
                    ForEach(surseOficiale){item in
                        Button(
                            action: {self.partialSheetManager.showPartialSheet({})
                                {Webview(url: URL(string: item.website)!)}
                            }
                            ,label: {
                                VStack{
                                    item.image
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        //.offset(y: -20)
                                    
                                    Text(item.nume)
                                        .font(.system(size: 12, weight: .regular))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color.black)
                                }
                                .frame(width: 100, height: 100)
                                .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white) .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5))
                           }
                        )
                        
                    }
                    
                    ForEach(0..<2){item in
                        Spacer()
                    }
                }
                .frame(height: 120)
                .offset(x: 20)
            }
        }
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
    Sursa(nume: "Evoluția \nCOVID-19", website: "https://datelazi.ro/", websitePrint: "www.datelazi.ro", image: Image("datelazi"), color: Color(#colorLiteral(red: 0.9383168221, green: 0.737329185, blue: 0.837926209, alpha: 1))),
    Sursa(nume: "Știri \noficiale", website: "https://stirioficiale.ro/informatii", websitePrint: "www.stirioficiale.ro", image: Image("stirioficiale"), color: Color(#colorLiteral(red: 0.4577399492, green: 0.8484248519, blue: 0.7813860774, alpha: 1))),
    Sursa(nume: "Ministerul \nSănătății", website: "http://www.ms.ro", websitePrint: "www.ms.ro", image: Image("ms"), color: Color(#colorLiteral(red: 0.05995995551, green: 0.2982606888, blue: 0.5433130264, alpha: 1))),
    Sursa(nume: "ECDC", website: "https://www.ecdc.europa.eu/en", websitePrint: "www.ecdc.europa.eu", image: Image("ecdc"), color: Color(#colorLiteral(red: 0.5605708957, green: 0.7272414565, blue: 0.1362667084, alpha: 1))),
    Sursa(nume: "Consiliul \nEuropei", website: "https://ec.europa.eu/info/live-work-travel-eu/coronavirus-response/safe-covid-19-vaccines-europeans_ro", websitePrint: "www.ec.europa.eu", image: Image("eu"), color: Color(#colorLiteral(red: 0.147555232, green: 0.2898129225, blue: 0.6446350217, alpha: 1))),
    Sursa(nume: "AEM", website: "https://www.ema.europa.eu/en", websitePrint: "www.ema.europa.eu", image: Image("ema"), color: Color(#colorLiteral(red: 0.05977845937, green: 0.2519665956, blue: 0.5820891857, alpha: 1))),
    Sursa(nume: "OMS", website: "https://who.int", websitePrint: "www.who.int", image: Image("who"), color: Color(#colorLiteral(red: 0.1968083084, green: 0.5436140895, blue: 0.8174911141, alpha: 1)))
]

struct Home_Previews: PreviewProvider {
    static var previews: some View {
        Home()
            .addPartialSheet()
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(PartialSheetManager())
    }
}



