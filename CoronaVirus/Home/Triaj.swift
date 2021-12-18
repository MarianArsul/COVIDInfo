//
//  Triaj.swift
//  CoronaVirus
//
//  Created by Milovan on 06.05.2021.
//

import SwiftUI

var pericol = 0

struct Triaj: View {
    var body: some View {
        ScrollView(.horizontal){
            ScrollViewReader{value in
                HStack {
                    HStack(spacing: 0) {
                        VStack {
                            VStack{
                                HStack {
                                    Text("Triaj")
                                        .font(.system(size: 25, weight: .bold))
                                    Spacer()
                                }
                                Text("epidemiologic")
                                    .font(.system(size: 30, weight: .bold))
                                    .offset(x: -85)
                            }
                            .padding(.leading, 20)
                            .offset(y: -40)
                            
                            GifView(imagine: "introducere_TE")
                                .frame(width: 200, height: 200)
                                .offset(y: -30)
                            
                            VStack{
                                HStack{
                                    Image(systemName: "list.number")
                                        .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                        .font(.system(size: 20, weight: .bold))
                                    
                                    Spacer()
                                    
                                    Text("Vei răspunde la câteva întrebări despre simptomele tale și contactul cu alte persoane")
                                        .font(.system(size: 15, weight: .regular))
                                }
                                .padding(.bottom, 10)
                                
                                HStack{
                                    Image(systemName: "hand.raised")
                                        .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                        .font(.system(size: 20, weight: .bold))
                                    
                                    Spacer()
                                    
                                    Text("Răspunsurile tale nu sunt partajate și analizate de către nimeni")
                                        .font(.system(size: 15, weight: .regular))
                                        .offset(x: 10)
                                }
                                .padding(.bottom, 10)
                                
                                HStack{
                                    Image(systemName: "checkmark.shield")
                                        .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                        .font(.system(size: 20, weight: .bold))
                                    
                                    Spacer()
                                    
                                    Text("Recomandările oferite de acest instrument nu constituie sfaturi medicale și nu ar trebui utilizate pentru a diagnostica sau trata afecțiunile medicale.")
                                        .font(.system(size: 15, weight: .regular))
                                        .offset(x: -26)
                                }
                                .padding(.bottom, 10)
                            }
                            .padding(.leading, 50)
                            .padding(.trailing, 50)
                            
                            Button(action: {withAnimation{value.scrollTo(3)}}){
                                HStack{
                                    Text("Am înțeles")
                                        .foregroundColor(Color.black)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                }
                                .frame(width: 300, height: 50)
                                .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                            }
                            .offset(y: 40)
                        }
                        .frame(width: screen.width, height: screen.height)
                        .id(2)
                        
                        VStack {
                            VStack(alignment: .leading){
                                Image(systemName: "staroflife.circle.fill")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                    .font(.system(size: 35, weight: .bold))
                                    .padding(.bottom, 1)
                                    .offset(x: -5)
                                
                                Text("Este o urgență?")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 30, weight: .bold))
                                    .padding(.bottom, 50)
                                
                                Text("Opriți-vă și sunați la 112 dacă suferiți de:")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 15, weight: .regular))
                                    .padding(.bottom, 1)
                                
                                Text("• Durere sau presiune toracică severă și constantă\n• Dificultăți extreme de respirație\n• Amețeală severă, constantă\n• Dezorientare gravă sau lipsă de răspuns\n• Față sau buze în nuanțe de albastru")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 15, weight: .regular))
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .offset(y: -100)
                            
                            VStack(spacing: 13){
                                Button(action: {withAnimation{value.scrollTo(4)}; pericol += 1}){
                                    HStack{
                                        Text("Sufăr de măcar una")
                                            .foregroundColor(Color.black)
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(5)}}){
                                    HStack{
                                        Text("Nu sufăr de niciuna")
                                            .foregroundColor(Color.black)
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                            }
                        }
                        .id(3)
                        .frame(width: screen.width, height: screen.height)
                        
                        VStack {
                            VStack(alignment: .leading){
                                Image(systemName: "staroflife.circle.fill")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                    .font(.system(size: 35, weight: .bold))
                                    .padding(.bottom, 1)
                                    .offset(x: -5)
                                
                                Text("Ar trebui să suni la 112")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 30, weight: .bold))
                                    .padding(.bottom, 10)
                                
                                Text("Pe baza simptomelor raportate, ar trebui să solicitați îngrijire imediat.")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 20, weight: .regular))
                                    .padding(.bottom, 1)
                                
                                
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .offset(y: -50)
                            
                        }
                        .frame(width: screen.width, height: screen.height)
                        .id(4)
                        
                        VStack {
                            VStack(alignment: .leading){
                                Text("Care este vârsta ta?")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 30, weight: .bold))
                                    .padding(.bottom, 50)
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .offset(y: -50)
                            
                            VStack(spacing: 13){
                                Button(action: {withAnimation{value.scrollTo(6)}}){
                                    HStack{
                                        Text("Sub 18")
                                            .foregroundColor(Color.black)
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(7)}}){
                                    HStack{
                                        Text("Între 18 și 64")
                                            .foregroundColor(Color.black)
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(7)}}){
                                    HStack{
                                        Text("65 sau mai bătrân")
                                            .foregroundColor(Color.black)
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                            }
                        }
                        .frame(width: screen.width, height: screen.height)
                        .id(5)
                        
                        VStack {
                            VStack(alignment: .leading){
                                Text("Acest instrument este destinat persoanelor care au cel puțin 18 ani")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 30, weight: .bold))
                                    .padding(.bottom, 50)
                                
                                Text("Accesați site-ul OMS pentru a obține informații despre COVID-19 și persoanele mai tinere.")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 20, weight: .regular))
                                    .padding(.bottom, 10)
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .offset(y: -50)
                            
                            VStack(spacing: 13){
                                Link(destination: URL(string: "www.who.int")!) {
                                    Button(action: {}){
                                        HStack{
                                            Text("Accesați who.int")
                                                .foregroundColor(Color.black)
                                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        }
                                        .frame(width: 300, height: 50)
                                        .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                    }
                                }
                            }
                        }
                        .frame(width: screen.width, height: screen.height)
                        .id(6)
                        
                        ZStack {
                            VStack(alignment: .leading){
                                Text("În ultimele 10 zile, ai fost testat pentru COVID-19?")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 30, weight: .bold))
                                    .padding(.bottom, 50)
                                    .offset(y: -100)
                                
                                Text("Includeți doar cel mai recent test de salivă, test oral sau test nazal.")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 20, weight: .regular))
                                    .padding(.bottom, 10)
                                    .offset(y: -100)
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .offset(y: -50)
                            
                            VStack(spacing: 13){
                                Button(action: {withAnimation{value.scrollTo(8)}; pericol += 1}){
                                    HStack{
                                        Text("Am fost testat și rezultatul este pozitiv")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(8)}}){
                                    HStack{
                                        Text("Am fost testat și rezultatul este negativ")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(8)}}){
                                    HStack{
                                        Text("Am fost testat, dar nu am primit rezultatul")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(8)}}){
                                    HStack{
                                        Text("Nu am fost testat în ultimele 10 zile")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                            }
                            .offset(y: 150)
                        }
                        .frame(width: screen.width, height: screen.height)
                        .id(7)
                        
                        ZStack {
                            VStack(alignment: .leading){
                                Text("Ai avut parte de următoarele simptome? ")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 30, weight: .bold))
                                    .padding(.bottom, 50)
                                    .offset(y: -100)
                                    .frame(height: 200)
                                
                                Text("• Febră sau frisoane\n• Dificultăți de respirație\n• Tuse\n• Pierderea gustului sau a mirosului\n• Gât uscat\n• Vomitat sau diaree")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 20, weight: .regular))
                                    .padding(.bottom, 10)
                                    .offset(y: -100)
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .offset(y: -50)
                            
                            VStack(spacing: 13){
                                Button(action: {withAnimation{value.scrollTo(9)}; pericol += 1}){
                                    HStack{
                                        Text("Da")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(10)}}){
                                    HStack{
                                        Text("Nu")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                            }
                            .offset(y: 150)
                        }
                        .frame(width: screen.width, height: screen.height)
                        .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
                        .id(8)
                        
                        ZStack {
                            VStack(alignment: .leading){
                                Text("Cât de severe sunt simptomele tale?")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 30, weight: .bold))
                                    .padding(.bottom, 50)
                                    .offset(y: -100)
                                    .frame(height: 200)
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .offset(y: -50)
                            
                            VStack(spacing: 13){
                                Button(action: {withAnimation{value.scrollTo(10)}}){
                                    HStack{
                                        Text("Simptomele au impact scăzut")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(10)}}){
                                    HStack{
                                        Text("Simptomele au un impact mediu")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(10)}}){
                                    HStack{
                                        Text("Simptomele au un impact major")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                            }
                            .offset(y: 150)
                        }
                        .frame(width: screen.width, height: screen.height)
                        .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
                        .id(9)
                        
                        ZStack {
                            VStack(alignment: .leading){
                                Text("Se aplică vreuna dintre acestea asupra ta?")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 30, weight: .bold))
                                    .padding(.bottom, 50)
                                    .offset(y: -100)
                                    .frame(height: 200)
                                
                                Text("• Obezitate\n• Fumat sau vaping\n• Însărcinată\n• Diabet, tensiune arterială amre\n• Astm, bronșită\n• Boli ale inimii\n• Sistem imunitar slăbit")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 20, weight: .regular))
                                    .padding(.bottom, 10)
                                    .offset(y: -100)
                            }
                            .padding(.leading, 30)
                            .padding(.trailing, 30)
                            .offset(y: -50)
                            
                            VStack(spacing: 13){
                                Button(action: {withAnimation{value.scrollTo(pericol > 0 ? 12 : 11)}; pericol += 1}){
                                    HStack{
                                        Text("Da")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                                
                                Button(action: {withAnimation{value.scrollTo(pericol > 0 ? 12 : 11)}}){
                                    HStack{
                                        Text("Nu")
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                            .multilineTextAlignment(.center)
                                            .foregroundColor(Color.black)
                                    }
                                    .frame(width: 300, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                                }
                            }
                            .offset(y: 150)
                        }
                        .frame(width: screen.width, height: screen.height)
                        .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
                        .id(10)
                        
                        VStack {
                            Text("Totul pare în regulă")
                                .font(.system(size: 30, weight: .bold))
                                .offset(y: -30)
                            
                            GifView_RepeatOnce(imagine: "success")
                                .frame(width: 200, height: 150)
                                .offset(y: -30)
                            
                            Text("Nu uita să te protejezi în continuare!")
                                .padding(.leading, 50)
                                .padding(.trailing, 50)
                                .font(.system(size: 15, weight: .regular))
                                .multilineTextAlignment(.center)
                                .offset(y: -30)
                            
                            Button(action: {withAnimation{value.scrollTo(13)}}) {
                                ZStack(alignment: .bottom){
                                   Image("preventie")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 300, height: 100)
                                        .accessibility(hidden: true)
                                    .offset(y: 50)
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Preventie")
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
                                    .frame(height: 100)
                                }
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                                .padding()
                                .accessibilityElement(children: .contain)
                                .frame(width: 300, height: 90)
                                .padding(.bottom, 20)
                            }
                            
                            Button(action: {withAnimation{value.scrollTo(14)}}) {
                                ZStack(alignment: .bottom){
                                   Image("simptome")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 300, height: 100)
                                        .accessibility(hidden: true)
                                    .offset(y: 50)
                                    
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("Simptome")
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
                                    //.frame(width: 250, hieght:)
                                    .accessibilityElement(children: .combine)
                                    .background(VisualEffectBlur())
                                    .frame(height: 100)
                                }
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                                .padding()
                                .accessibilityElement(children: .contain)
                                .frame(width: 300, height: 90)
                            }
                            
                            Button(action: {withAnimation{value.scrollTo(2)}; pericol = 0}){
                                HStack{
                                    Text("Redă testul")
                                        .foregroundColor(Color.black)
                                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                }
                                .frame(width: 300, height: 50)
                                .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                            }
                            .offset(y: 30)
                        }
                        .frame(width: screen.width, height: screen.height)
                        .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
                        .id(11)
                    }
                    
                    VStack {
                        Text("Contactează un medic")
                            .font(.system(size: 30, weight: .bold))
                            .offset(y: -30)
                        
                        VStack(){
                            ScrollView(.vertical, showsIndicators: false){
                                GifView(imagine: "ajutor_Simptome")
                                .frame(width:300, height: 250)
                                    .offset(y: 60)
                                
                                Text("Cere ajutor")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                                    .font(.system(size: 20, weight: .bold))
                                    .offset(y: 20)
                                
                                Text("Dacă ai simptome, sau dacă ai nevoie de informații cu privire la transmiterea și răspândirea virusului, te rugăm să apelezi TelVerde la numărul 0800.800.358")
                                    .font(.system(size: 13, weight: .bold))
                                    .fontWeight(.regular)
                                    .multilineTextAlignment(.center)
                                    .padding(.leading, 20)
                                    .padding(.trailing, 20)
                                    .offset(y: 50)
                            
                                Image(systemName: "chevron.compact.down")
                                .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                                .font(.system(size: 20, weight: .bold))
                                .offset(y: 70)
                            
                            Text("Numărul TELVERDE nu este un număr de urgență, este o linie telefonică alocată strict pentru informarea cetățenilor. De asemenea, românii aflați în străinătate pot solicita informații despre prevenirea și combaterea virusului la linia special dedicată lor +4021.320.20.20 \nDacă consideri că situația ta este una gravă,  apelează numărul unic de urgență : 112")
                                .font(.system(size: 13, weight: .bold))
                                .fontWeight(.regular)
                                .multilineTextAlignment(.center)
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .offset(y: 100)
                                
                                ForEach(1..<18){ i in
                                    Spacer()
                                    }
                                }
                            }
                            .frame(width: 300, height: 450)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                            )
                        
                        Button(action: {withAnimation{value.scrollTo(2)}; pericol = 0}){
                            HStack{
                                Text("Redă testul")
                                    .foregroundColor(Color.black)
                                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            }
                            .frame(width: 300, height: 50)
                            .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                        }
                        .offset(y: 30)
                    }
                    .frame(width: screen.width, height: screen.height)
                    .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
                    .id(12)
                    
                    ZStack{
                        PreventieView()
                        
                        Button(action: {withAnimation{value.scrollTo(11)}}) {
                            HStack{
                                Image(systemName: "chevron.backward")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                                    .font(.system(size: 20, weight: .bold))
                                
                                Text("Înapoi la rezultate")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color.black)
                            }
                        }
                        .offset(y: -340)
                        .offset(x: -80)
                    }
                    .frame(width: screen.width, height: screen.height)
                    .id(13)
                    
                    ZStack{
                        SimptomeView()
                        
                        Button(action: {withAnimation{value.scrollTo(11)}}) {
                            HStack{
                                Image(systemName: "chevron.backward")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                                    .font(.system(size: 20, weight: .bold))
                                
                                Text("Înapoi la rezultate")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color.black)
                            }
                        }
                        .offset(y: -340)
                        .offset(x: -80)
                    }
                    .frame(width: screen.width, height: screen.height)
                    .id(14)
                }
            }
        }
        .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
        //.edgesIgnoringSafeArea(.all)
    }
}

struct Triaj_Previews: PreviewProvider {
    static var previews: some View {
        Triaj()
    }
}
