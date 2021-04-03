//
//  PreventieView.swift
//  CoronaVirus
//
//  Created by Milovan on 31.03.2021.
//

import SwiftUI

struct PreventieView: View {
    
    var body: some View {
        VStack{
            HStack{
                Image("covid1")
                    .aspectRatio(contentMode: .fill)
                    .zIndex(1)
                
                Spacer()
                Link(destination: URL(string: "https://cetrebuiesafac.ro/cum-ne-protejam")!){
                    Image(systemName: "info.circle")
                        .foregroundColor(Color.white)
                        .font(.system(size: 25, weight: .bold))
                        .zIndex(2)
                }
            }
            .position(x: 160 ,y: 90)
            .padding(.leading, 30)
            .padding(.trailing, 30)
            
            HStack {
                VStack(alignment: .leading){
                    Text("Prevenție")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color.white)
                    Text("Cum ne protejăm ?")
                        .font(.system(size: 21, weight: .bold))
                        .fontWeight(.regular)
                        .foregroundColor(Color.white)
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
                                    .foregroundColor(Color(#colorLiteral(red: 0.9734770656, green: 0.8399353623, blue: 0.6799591184, alpha: 1)))
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
                                RoundedRectangle(cornerRadius: 20)
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
            
            Link(destination: URL(string: "https://cetrebuiesafac.ro/cum-ne-protejam/recomandari-privind-conduita-sociala-responsabila")!){
                    HStack{
                        Image(systemName: "info.circle")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(Color(#colorLiteral(red: 0.9734770656, green: 0.8399353623, blue: 0.6799591184, alpha: 1)))
                            .padding(.leading, 20)
                            .padding(.trailing, 5)
                        
                        //Spacer()
                        VStack(alignment: .leading){
                            Text("Pentru mai multe informații accesează")
                                .font(.system(size: 14, weight: .regular))
                                .padding(.trailing, 20)
                                .foregroundColor(Color.black)
                            Text("www.cetrebuiesafac.ro")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(#colorLiteral(red: 0.9734770656, green: 0.8399353623, blue: 0.6799591184, alpha: 1)))
                        }
                        
                    }
                    .frame(width: 330, height: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white))
                    .offset(y: -50)
            }
        }
        .frame(width: screen.width+30, height: screen.height+13)
        .background(Color(#colorLiteral(red: 0.9734770656, green: 0.8399353623, blue: 0.6799591184, alpha: 1)))
    }
}

struct PreventieView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PreventieView()
        }
    }
}

struct Preventie : Identifiable{
    var id = UUID()
    var nume : String
    var descriere : String
    var image : String
}

let dataPreventie = [
    Preventie(nume: "Spală-te pe mâini", descriere: "Spală-te des pe mâini cu apă și săpun timp de cel puțin 20 de secunde, mai ales după ce ai fost într-un loc public sau după ce îți sufli nasul, tușești sau strănuți. Pentru a te șterge pe mâini folosește, de preferat, prosoape de hârtie.", image: "01"),
    Preventie(nume: "Poartă masca de protecție", descriere: "Trebuie să porți o mască atunci când ești în preajma altor persoane. Masca de protecție/masca chirurgicală îi protejează pe cei din jurul tău, în cazul în care ai simptome de gripă sau răceală, întrucât previne răspândirea virusului pe cale respiratorie. Masca de protecție trebuie să acopere complet nasul și gura persoanei care o poartă.", image: "02"),
    Preventie(nume: "Utilizează un produs de dezinfectare a mâinilor", descriere: "Dacă nu sunt disponibile apa și săpunul, utilizează un produs de dezinfectare a mâinilor. Acoperă cu lichidul toată suprafața mâinilor și freacă-ți mâinile până când se simt uscate.", image: "03"),
    Preventie(nume: "Autoizolarea", descriere: "Autoizolează-te pentru 14 zile dacă ai călătorit în regiuni afectate de COVID-19, ai intrat în contact direct cu persoanale cu simptome sau cu persoanele care au fost confirmate cu coronavirus.", image: "04"),
    Preventie(nume: "Evită contactul direct", descriere: "Coronavirus se poate răspândi între persoane care sunt în contact strâns (strângerea mâinilor, îmbrățișările, sărutul obrajilor sau al mâinilor, atingerea fețelor cu mâinile).", image: "05")
]
