//
//  Home2.0.swift
//  CoronaVirus
//
//  Created by Milovan on 16.05.2021.
//

import SwiftUI
import PartialSheet

struct Home2_0: View {
    
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
        ZStack {
            if showSettings == true {
                
            }
            
            NavigationView(){
                ScrollView(showSettings ? [] : .vertical) {
                    VStack{
                        HStack {
                            Text(timeOfDay() + "MILOVAN")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color(#colorLiteral(red: 0.252196312, green: 0.4833931327, blue: 0.996443212, alpha: 1)))
                                
                            Spacer()
                                
                        }
                        .offset(y: -90)
                        .offset(x: -5)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        
                        HStack{
                            Text("Setari")
                        }
                        .frame(width: 50, height: 20)
                        
                        
                        
                        Divider()
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            .offset(y: -70)
                        
                        ScrollView(.horizontal, showsIndicators: false){
                            HStack(spacing: 10){
                                Button(action: {showSympthomsForm.toggle()}){
                                    ZStack {
                                        Image("triaj")
                                            .resizable()
                                            .frame(width: 200, height: 200)
                                            .offset(x: 60)
                                        
                                        VStack(alignment: .leading){
                                            Text("Triaj")
                                                .font(.system(size: 25, weight: .bold))
                                            
                                            Text("Epidemiologic")
                                                .font(.system(size: 25, weight: .bold))
                                            
                                            HStack{
                                                Text("Află mai multe")
                                                
                                                Image(systemName: "chevron.right")
                                                    
                                            }
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundColor(Color.black)
                                        }
                                        .foregroundColor(Color.black)
                                        .offset(x: -40)
                                    }
                                    .frame(width: 300, height: 190)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1))))
                                }
                                .sheet(isPresented: $showSympthomsForm){Triaj()}
                                
                                ZStack{
                                    Image("vaccine-intro")
                                        .resizable()
                                        .frame(width: 160, height: 160)
                                        .offset(x: 80)
                                    
                                    VStack(alignment: .leading){
                                        Text("Hai la")
                                            .font(.system(size: 25, weight: .bold))
                                        
                                        Text("VACCINARE!")
                                            .font(.system(size: 25, weight: .bold))
                                        
                                        HStack{
                                            Text("Află mai multe")
                                            
                                            Image(systemName: "chevron.right")
                                                
                                        }
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(Color.black)
                                    }
                                    .offset(x: -45)
                                }
                                .frame(width: 300, height: 190)
                                .background(RoundedRectangle(cornerRadius: 10) .fill(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1))))
                                //.border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                                
                                ZStack{
                                    Image("news_U")
                                        .resizable()
                                        .frame(width: 160, height: 160)
                                        .offset(x: 80)
                                    
                                    VStack(alignment: .leading) {
                                        Text("ULTIMLE STIRI")
                                            .foregroundColor(Color(#colorLiteral(red: 0.252196312, green: 0.4833931327, blue: 0.996443212, alpha: 1)))
                                            .font(.system(size: 15, weight: .bold))
                                            .offset(x: 5)
                                        
                                        
                                    }
                                    .offset(x: -50)
                                }
                                .frame(width: 300, height: 190)
                                .background(RoundedRectangle(cornerRadius: 10) .fill(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1))))
                                //.border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                                
                                ForEach(0..<2){item in
                                    Spacer()
                                }
                            }
                            .padding(.leading, 20)
                        }
                        .offset(y: -60)
                                        
                        VStack{
                            HStack{
                                Text("INFORMAȚII")
                                
                                Spacer()
                            }
                            .foregroundColor(Color.black)
                            .font(.system(size: 15, weight: .bold))
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack(spacing: -20){
                                    Button(action: {self.showPreventie.toggle()}){CardsView(card: cards[0]).offset(x: 30)}.sheet(isPresented: $showPreventie){PreventieView().zIndex(1)}
                                    Button(action: {self.showSimptome.toggle()}){CardsView(card: cards[1]).offset(x: 30)}.sheet(isPresented: $showSimptome){SimptomeView()}
                                    NavigationLink(destination: IntrebariFrecvente()) {
                                        CardsView(card: cards[2]).offset(x: 30)}
                                    Button(action: {self.showDocumente.toggle()}){CardsView(card: cards[3]).offset(x: 30)}.sheet(isPresented: $showDocumente){DocumentsView()}
                                    
                                    Spacer()
                                    Spacer()
                                }
                                .offset(x: -25)
                                .offset(y: -8)
                            }
                        }
                        .offset(y: -50)
                        
                        VStack{
                            HStack{
                                Text("STATISTICI")
                                
                                Spacer()
                                
                                HStack{
                                    Text("Vezi mai mult")
                                    
                                    Image(systemName: "arrow.right")
                                    
                                }
                                .foregroundColor(Color(#colorLiteral(red: 0.252196312, green: 0.4833931327, blue: 0.996443212, alpha: 1)))
                            }
                            .foregroundColor(Color.black)
                            .font(.system(size: 15, weight: .bold))
                            .padding(.leading, 24)
                            .padding(.trailing, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10){
                                    ZStack{
                                        VStack(alignment: .leading){
                                            Text("Cazuri confirmate")
                                                .font(.system(size: 20, weight: .bold))
                                                .offset(y: 5)
                                                .offset(x: -15)
                                            
                                        }
                                        .frame(width: 250, height: 80)
                                        .background(Color.white)
                                        .offset(y: -80)
                                        
                                        .zIndex(2)
                                        
                                        ZStack {
                                            Webview(url: URL(string: "https://datelazi.ro/embed/confirmed_cases")!)
                                                .offset(y: 0)
                                        }
                                        .frame(width: 260, height: 280)
                                        
                                    }
                                    .frame(width: 220, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                                    
                                    ZStack{
                                        VStack(alignment: .leading){
                                            Text("Vaccinuri administrate")
                                                .font(.system(size: 20, weight: .bold))
                                                .offset(y: 5)
                                                //.offset(x: 10)
                                            
                                        }
                                        .frame(width: 250, height: 80)
                                        .background(Color.white)
                                        .offset(y: -80)
                                        .zIndex(2)
                                        
                                        ZStack {
                                            Webview(url: URL(string: "https://datelazi.ro/embed/total_vaccine")!)
                                        }
                                        .frame(width: 260, height: 280)
                                    }
                                    .frame(width: 250, height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                                    
                                        
                                    ForEach(0..<2){item in
                                        Spacer()
                                    }
                                }
                                .frame(height: 230)
                                .padding(.leading, 24)
                            }
                            .offset(y: -10)
                        }
                        .offset(y: -60)
                        
                        SurseSigure()
                            .offset(y: -65)

                        VStack{
                            HStack {
                                Text("ULTIMELE INFORMAȚII OFICIALE")

                                Spacer()
                            }
                            .foregroundColor(Color.black)
                            .font(.system(size: 15, weight: .bold))
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            
                            VStack(spacing: -10){
                                ForEach(0..<articleData.count){item in
                                    Button(
                                        action: {self.partialSheetManager.showPartialSheet({})
                                            {Webview(url: URL(string: articleData[item].link)!)}
                                        }
                                        ,label: {
                                            News(article: articleData[item])}
                                    )
                                    .id(item)
                                }
                            }
                        }
                        .offset(y: -60)
                    }
                    .offset(y: 20)
                    .navigationBarTitle("Acasă")
                }
            }
            .offset(y: showSettings ? 300 : 0)
        }
    }
}

struct Home2_0_Previews: PreviewProvider {
    static var previews: some View {
        Home2_0()
            .addPartialSheet()
            .environmentObject(PartialSheetManager())
    }
}
