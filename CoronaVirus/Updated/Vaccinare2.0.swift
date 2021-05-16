//
//  Vaccinare2.0.swift
//  CoronaVirus
//
//  Created by Milovan on 16.05.2021.
//  Accent color: FFC727

import SwiftUI

struct Vaccinare2_0: View {
    
    @State var showIntroQuestion1 = false
    @State var showIntroQuestion2 = false
    @State var showResurseInfoSigure = false
    @State var showResurseInfoInselatoare = false
    @State var showResurseDict = false
    
    var body: some View {
        NavigationView(){
            ScrollView(.vertical){
                Divider()
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 10){
                        Button(action: {showIntroQuestion1.toggle()}) {
                            ZStack {
                                Image("vaccinare_U")
                                    .resizable()
                                    .frame(width: 200, height: 200)
                                    .offset(x: 70)
                                
                                VStack(alignment: .leading){
                                    Text("De ce ar trebui")
                                        .font(.system(size: 25, weight: .bold))
                                    
                                    Text("să mă")
                                        .font(.system(size: 25, weight: .bold))
                                    
                                    Text("vaccinez?")
                                        .font(.system(size: 25, weight: .bold))
                                    
                                    HStack{
                                        Text("Află mai multe")
                                        
                                        Image(systemName: "chevron.right")
                                            
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.black)
                                    .offset(y: 5)
                                }
                                .foregroundColor(Color.black)
                                .offset(x: -40)
                            }
                            .frame(width: 300, height: 190)
                            .background(RoundedRectangle(cornerRadius: 10) .fill(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1))))
                        }
                        .sheet(isPresented: $showIntroQuestion1){
                            Webview(url: URL(string: "https://vaccinare-covid.gov.ro/resurse/intrebari-si-raspunsuri/")!)
                                .frame(height: screen.height + 200)
                        }
                        
                        ZStack {
                            Image("creareVaccin_U")
                                .resizable()
                                .frame(width: 200, height: 200)
                                .offset(x: 50)
                            
                            VStack(alignment: .leading){
                                Text("Etapele creării")
                                    .font(.system(size: 25, weight: .bold))
                                
                                Text("unui vaccin")
                                    .font(.system(size: 25, weight: .bold))
                                
                                
                                HStack{
                                    Text("Află mai multe")
                                    
                                    Image(systemName: "chevron.right")
                                        
                                }
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(Color.black)
                                .offset(y: 5)
                            }
                            .foregroundColor(Color.black)
                            .offset(x: -40)
                        }
                        .frame(width: 300, height: 190)
                        .background(RoundedRectangle(cornerRadius: 10) .fill(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1))))
                        
                        Spacer()
                        Spacer()
                    }
                    .padding(.leading, 20)
                    
                }
                .offset(y: 10)
                
                VStack{
                    Text("RESURSE UTILE")
                        .foregroundColor(Color.black)
                        .font(.system(size: 15, weight: .bold))
                        .offset(x: -115)
                        .offset(y: 20)
                    
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack(spacing: -20){
                            Button(action: {showResurseInfoSigure.toggle()}) {
                                ZStack(alignment: .bottom){
                                    ZStack {
                                        Image(resurseUtileArray[0].image)
                                            .resizable()
                                            .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                                            //.accessibility(hidden: true)
                                    }
                                    .frame(width: 250, height: 330)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1))))
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(resurseUtileArray[0].titlu)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Color(#colorLiteral(red: 0.1024787799, green: 0.1775858402, blue: 0.2037084699, alpha: 1)))
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .frame(width: 250)
                                    .accessibilityElement(children: .combine)
                                    .background(VisualEffectBlur())
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .padding()
                                .accessibilityElement(children: .contain)
                            }
                            .sheet(isPresented: $showResurseInfoSigure){
                                Webview(url: URL(string: resurseUtileArray[0].link)!)
                                    .frame(height: screen.height + 200)
                            }
                            
                            Button(action: {showResurseInfoInselatoare.toggle()}){
                                ZStack(alignment: .bottom){
                                    ZStack {
                                        Image(resurseUtileArray[1].image)
                                            .resizable()
                                            .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                                            //.accessibility(hidden: true)
                                    }
                                    .frame(width: 250, height: 330)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1))))
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(resurseUtileArray[1].titlu)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Color(#colorLiteral(red: 0.1024787799, green: 0.1775858402, blue: 0.2037084699, alpha: 1)))
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .frame(width: 250)
                                    .accessibilityElement(children: .combine)
                                    .background(VisualEffectBlur())
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .padding()
                                .accessibilityElement(children: .contain)
                            }
                            .sheet(isPresented: $showResurseInfoInselatoare){
                                Webview(url: URL(string: resurseUtileArray[1].link)!)
                                    .frame(height: screen.height + 200)
                            }
                            
                            Button(action: {showResurseDict.toggle()}) {
                                ZStack(alignment: .bottom){
                                    ZStack {
                                        Image(resurseUtileArray[2].image)
                                            .resizable()
                                            .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                                            //.accessibility(hidden: true)
                                    }
                                    .frame(width: 250, height: 330)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1))))
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(resurseUtileArray[2].titlu)
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Color(#colorLiteral(red: 0.1024787799, green: 0.1775858402, blue: 0.2037084699, alpha: 1)))
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .frame(width: 250)
                                    .accessibilityElement(children: .combine)
                                    .background(VisualEffectBlur())
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .padding()
                                .accessibilityElement(children: .contain)
                            }
                            .sheet(isPresented: $showResurseDict){
                                Webview(url: URL(string: resurseUtileArray[2].link)!)
                                    .frame(height: screen.height + 200)
                            }
                        }
                        .padding(.leading, 7)
                    }
                    .padding(.top, 10)
                }
                
                VStack{
                    HStack{
                        Text("STATISTICI VACCINARE")
                        
                        Spacer()
                        
                    }
                    .foregroundColor(Color.black)
                    .font(.system(size: 15, weight: .bold))
                    .padding(.leading, 23)
                    .padding(.trailing, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10){
                            ZStack{
                                VStack(alignment: .leading){
                                    Text("Doze administrate")
                                        .font(.system(size: 20, weight: .bold))
                                        .offset(y: 5)
                                        .offset(x: -20)
                                    
                                }
                                .frame(width: 250, height: 80)
                                .background(Color.white)
                                .offset(y: -80)
                                
                                .zIndex(2)
                                
                                ZStack {
                                    Webview(url: URL(string: "https://datelazi.ro/embed/total_vaccine")!)
                                        .offset(y: 0)
                                }
                                .frame(width: 260, height: 280)
                                
                            }
                            .frame(width: 250, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                            
                            ZStack{
                                VStack(alignment: .leading){
                                    Text("Persoane imunizate")
                                        .font(.system(size: 20, weight: .bold))
                                        .offset(y: 5)
                                    
                                }
                                .frame(width: 250, height: 80)
                                .background(Color.white)
                                .offset(y: -80)
                                .zIndex(2)
                                
                                ZStack {
                                    Webview(url: URL(string: "https://datelazi.ro/embed/vaccine_immunization")!)
                                        
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
                        .padding(.leading, 23)
                    }
                    .offset(y: -10)
                }
                    
            }
            .navigationTitle("Vaccinare")
        }
    }
}

struct Vaccinare2_0_Previews: PreviewProvider {
    static var previews: some View {
        Vaccinare2_0()
    }
}

struct creareaUnuiVaccin : View {
    var body: some View{
        VStack{
            HStack{
                Spacer()
                
            }
            .position(x: 160 ,y: 90)
            .padding(.leading, 30)
            .padding(.trailing, 30)
            
            HStack {
                VStack(alignment: .leading){
                    Text("Etapele crearii unui vaccin")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color.black)
                }
                .position(x: 160, y: -100)
                .offset(x: -30)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false){
                HStack(spacing: 10) {
                    ForEach(dataPreventie){ item in
                        VStack(){
                            
                                GifView(imagine: item.image)
                                .frame(width:300, height: 250)
                                
                                Text(item.nume)
                                    .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                                    .font(.system(size: 20, weight: .bold))
                                    .offset(y: -30)
                                
                                Text(item.descriere)
                                    .font(.system(size: 13, weight: .bold))
                                    .fontWeight(.regular)
                                    .multilineTextAlignment(.center)
                                    .padding(.leading, 20)
                                    .padding(.trailing, 20)
                            
                                }
                            .frame(width: 300, height: 450)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.white)
                            )
                            .offset(x: 60)
                            .zIndex(2)
                    }
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                }}
                .position(x: 195, y: -70)
                .zIndex(1)
        }
        .frame(width: screen.width+30, height: screen.height+13)
        .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
    }
}

struct creareVaccin : Identifiable{
    var id = UUID()
    var nrEtapa: String
    var descriereEtapa: String
    var imagineEtapa: String
}

let creareVaccinData = [
    creareVaccin(nrEtapa: "Etapa 1", descriereEtapa: "Companiile producătoare depun rezultatele studiilor clinice la Agenția Europeană a Medicamentului (EMA) și solicită evaluarea și autorizarea vaccinurilor", imagineEtapa: ""),
    creareVaccin(nrEtapa: "Etapa 3", descriereEtapa: "Comisia Europeană analizează raportul final de evaluare al Agenției Europene a Medicamentului și decide emiterea unei autorizații de punere pe piață a vaccinului", imagineEtapa: ""),
    creareVaccin(nrEtapa: "Etapa 4", descriereEtapa: "Autoritățile naționale aprobă vaccinul nou autorizat și monitorizează procesul de vaccinare", imagineEtapa: "")
]
