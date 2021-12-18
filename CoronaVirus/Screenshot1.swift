//
//  Screenshot1.swift
//  CoronaVirus
//
//  Created by Milovan on 16.05.2021.
//

import SwiftUI

struct Screenshot1: View {
    var body: some View {
        ZStack{
            Image("screenshotOne")
                .resizable()
                .frame(width: 700, height: 500)
                .offset(x: -170)
            
            VStack{
                Image("RoundedIcon")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .offset(y: -30)
                
                Text("COVIDInfo")
                    .foregroundColor(Color.black)
                    .font(.system(size: 30, weight: .bold))
                    .offset(y: -30)
                
                HStack{
                    Image(systemName: "heart.text.square")
                        .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                        .font(.system(size: 15, weight: .bold))
                    
                    //Spacer()
                    
                    Text("Află cum să te protejezi și ce simptome pot apărea , ultimele știri și de unde să te informerzi")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.black)
                        .frame(width: 200)
                        .offset(x: 10)
                }
                .padding(.bottom, 10)
                
                HStack{
                    Image(systemName: "arrow.up.forward.circle")
                        .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                        .font(.system(size: 15, weight: .bold))
                    
                    //Spacer()
                    
                    Text("Vizualizează ultimele statistici și află evoluția pandemiei în România")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.black)
                        .frame(width: 200)
                        .offset(x: 9)
                    
                }
                .padding(.bottom, 10)
                
                HStack{
                    Image(systemName: "staroflife")
                        .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                        .font(.system(size: 15, weight: .bold))
                    
                    //Spacer()
                    
                    Text("Află mai multe despre vaccinurile aprobate și cum poți spune stop pandemiei")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.black)
                        .frame(width: 200)
                        //.offset(x: 10)
                }
                .padding(.bottom, 10)
                
                Text("An app by Milovan Arsul")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.black)
                    .offset(y: 80)
            }
            .frame(width: 300)
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .offset(x: 320)
            .offset(y: 20)
        }
        .frame(width: screen.width, height: 500)
        .background(Color(#colorLiteral(red: 0.9570131898, green: 0.9775220752, blue: 0.9996746182, alpha: 1)))
        //.background(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1)))
    }
}

struct Screenshot1_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Screenshot1()
        }
    }
}
