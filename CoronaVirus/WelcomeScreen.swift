//
//  WelcomeScreen.swift
//  CoronaVirus
//
//  Created by Milovan on 13.05.2021.
//

import SwiftUI

struct WelcomeScreen: View {
    
    @State var fieldName = ""
    @State var currentIndex = 0
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false){
            ScrollViewReader{welcome in
                HStack(spacing: 0){
                    ZStack{
                        Image("welcome1")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 200)
                            .offset(y: -200)
                        
                        Text("Salut! ")
                            .foregroundColor(Color.black)
                            .font(.system(size: 40, weight: .bold))
                            .offset(y: -60)
                        
                        Text("Hai sa ne cunoastem mai bine...")
                            .foregroundColor(Color.black)
                            .font(.system(size: 20, weight: .bold))
                            .offset(y: -20)
                        
                        Text("Introdu numele tau in campul de mai jos")
                            .foregroundColor(Color.black)
                            .font(.system(size: 13, weight: .bold))
                            .offset(y: 100)
                        
                        HStack {
                            TextField("      Numele meu este...", text: $fieldName)
                                .frame(width: 200,height: 40)
                                .background(RoundedRectangle(cornerRadius: 20) .fill(Color.gray))
                                .font(.system(size: 13, weight: .bold))
                                .offset(y: 150)
                            
                            Button(action: {withAnimation{welcome.scrollTo(2)}; name = fieldName}){
                                HStack{
                                    Text("OK")
                                        .foregroundColor(Color.white)
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .frame(width: 70, height: 40)
                                .background(RoundedRectangle(cornerRadius: 20) .fill(Color.blue))
                            }
                            .offset(y: 150)
                        }
                        
                        Text("Poti schimba mai tarziu aceasta informatie in setari. \nAceste informatii nu sunt partajate cu nimeni si niciodata nu parasesc dispozitivul dumneavoastra. \nNumele dumneavoastra este folosit pentru oferirea unei experintele mai bune de utilizare. \nPuteti sa optati din introducerea acestuia.")
                            .font(.system(size: 11, weight: .regular))
                            .multilineTextAlignment(.center)
                            .offset(y: 330)
                            .padding(.leading, 40)
                            .padding(.trailing, 40)
                    }
                    .frame(width: screen.width, height: screen.height)
                    .background(Color.white)
                    .id(1)
                    
                    ZStack{
                        Image("welcome2")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 200)
                            .offset(y: -200)
                        
                        if name != ""{
                            Text("Incantat de cunostinta, \(name)!")
                                .foregroundColor(Color.black)
                                .font(.system(size: 20, weight: .bold))
                                .offset(y: -70)
                        }
                        
                        Text("Multumim ca ne utilizezi aplicatia :)")
                            .foregroundColor(Color.black)
                            .font(.system(size: 15, weight: .bold))
                            .offset(y: -40)
                        
                        Text("Gata de explorat? ")
                            .foregroundColor(Color.black)
                            .font(.system(size: 25, weight: .bold))
                            .offset(y: 70)
                        
                        Text("Inainte de toate, dorim sa avem acces la locatia ta.\nAceasta ne ajuta sa iti oferim statistici si recomandari personalizate. ")
                            .font(.system(size: 12, weight: .bold))
                            .multilineTextAlignment(.center)
                            .offset(y: 130)
                            .padding(.leading, 40)
                            .padding(.trailing, 40)
                        
                        Text("\nAceste informatii nu sunt partajate cu nimeni si niciodata nu parasesc dispozitivul dumneavoastra. Puteti sa renuntati la folosirea locatiei, insa unele functionalitati pot inceta sa functioneze. \nAceste functionalitati pot fi modificate oricand din setari.")
                            .font(.system(size: 12, weight: .regular))
                            .multilineTextAlignment(.center)
                            .offset(y: 330)
                            .padding(.leading, 40)
                            .padding(.trailing, 40)
                        
                        Button(action: {withAnimation{welcome.scrollTo(3)}}) {
                            HStack{
                                Text("Mai departe")
                                
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(Color(#colorLiteral(red: 0.8980392157, green: 0.4, blue: 0.4666666667, alpha: 1)))
                            .font(.system(size: 18, weight: .bold))
                        }
                        .offset(y: 220)
                    }
                    .frame(width: screen.width, height: screen.height)
                    .id(2)
                    
                    ZStack{
                        Image("welcome3")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 300, height: 200)
                            .offset(y: -200)
                        
                        Text("Pregatit?")
                            .foregroundColor(Color.black)
                            .font(.system(size: 30, weight: .bold))
                            .offset(y: -50)
                        
                        Text("Iata ce iti oferim: ")
                            .foregroundColor(Color.black)
                            .font(.system(size: 19, weight: .bold))
                            
                        
                        VStack{
                            HStack{
                                Image(systemName: "heart.text.square")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                    .font(.system(size: 20, weight: .bold))
                                
                                Spacer()
                                
                                Text("Afla cum sa te protejezi si ce simptome pot aparea, ultimele stiri si de unde sa te informerzi.")
                                    .font(.system(size: 15, weight: .regular))
                                    .offset(x: 10)
                            }
                            .padding(.bottom, 10)
                            
                            HStack{
                                Image(systemName: "arrow.up.forward.circle")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                    .font(.system(size: 20, weight: .bold))
                                
                                Spacer()
                                
                                Text("Vizualizeaza ultimele statistici si incidenta pentru locatia ta")
                                    .font(.system(size: 15, weight: .regular))
                                    .offset(x: -20)
                            }
                            .padding(.bottom, 10)
                            
                            HStack{
                                Image(systemName: "staroflife")
                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                    .font(.system(size: 20, weight: .bold))
                                
                                Spacer()
                                
                                Text("Gaseste un centru de vaccinare in apropiere de tine pentru a pune stop pandemiei.")
                                    .font(.system(size: 15, weight: .regular))
                                    .offset(x: 10)
                            }
                            .padding(.bottom, 10)
                        }
                        .padding(.leading, 50)
                        .padding(.trailing, 50)
                        .offset(y: 150)
                        
                        Button(action: {withAnimation{welcome.scrollTo(4)}}) {
                            HStack{
                                Text("Mai departe")
                                
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(Color(#colorLiteral(red: 0.8980392157, green: 0.4, blue: 0.4666666667, alpha: 1)))
                            .font(.system(size: 18, weight: .bold))
                        }
                        .offset(y: 300)
                        
                    }
                    .frame(width: screen.width, height: screen.height)
                    .id(3)
                    
                    ContentView()
                        //.offset(y: -10)
                        .id(4)
                }
            }
        }
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}

struct WelcomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeScreen()
    }
}


