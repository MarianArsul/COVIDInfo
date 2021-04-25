//
//  SimptomeView.swift
//  CoronaVirus
//
//  Created by Milovan on 02.04.2021.
//

import SwiftUI

struct SimptomeView: View {
    
    var body: some View {
        VStack{
            HStack{
                Image("simptome_Bg")
                    .aspectRatio(contentMode: .fill)
                    .zIndex(1)
                    .offset(y: 460)
                    .offset(x: 870)
                
                Spacer()
            }
            .position(x: 160 ,y: 90)
            .padding(.leading, 30)
            .padding(.trailing, 30)
            
            HStack {
                VStack(alignment: .leading){
                    Text("Simptome")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(Color.black)
                        .offset(x: -15)
                }
                .position(x: 160, y: -100)
                .offset(x: -30)
                
                Spacer()
                
                
            }
            
            ScrollView(.horizontal){
                HStack(spacing: 10) {
                    ForEach(dataSimptome){ item in
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
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                            )
                            .offset(x: 60)
                            .zIndex(2)
                    }
                    
                    VStack(){
                        ScrollView(.vertical, showsIndicators: false){
                            GifView(imagine: "atentie_Simptome")
                            .frame(width:300, height: 250)
                                .offset(y: 60)
                            
                            Text("Atenție")
                                .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                                .font(.system(size: 20, weight: .bold))
                                .offset(y: 50)
                            
                            Text("Unele persoane pot să fie infectate, dar nu dezvoltă niciun simptom.")
                                .font(.system(size: 13, weight: .bold))
                                .fontWeight(.regular)
                                .multilineTextAlignment(.center)
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .offset(y: 70)
                            
                            Image(systemName: "chevron.compact.down")
                                .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                                .font(.system(size: 20, weight: .bold))
                                .offset(y: 100)
                            
                            Text("Alte simptome care sunt mai puțîn frecvente și care pot să apară la unele persoane sunt: durerile, congestia nazală, conjunctivită, cefaleea, durerile de gât, diareea, pierderea simțului gustului și a mirosului, erupțiile cutanate și inrosirea degetelor de la mâini și picioare (apar că și cum ar fi degerate). Aceste simptome sunt de obicei ușoare și se manifestă gradual. La alte persoane infectate, apar doar simptome foarte ușoare. \nMajoritatea persoanelor (80%) afectate se recuperează fără a avea nevoie de tratament la spital. Aproximativ 1 din 5 persoane cu COVID-19 prezintă o formă gravă, cu probleme respiratorii. Persoanele în vârstă și cele cu alte probleme de sănătate (hipertensiune arterială, afecțiuni cardiace, diabet, cancer) prezintă riscuri de complicații. Totuși, oricine poate face o formă gravă a COVID-19. Indiferent de vârstă, persoanele care au febra și/sau tușe asociate cu probleme respiratorii (dispnee), durere sau presiune in piept și afectarea mișcării și a vorbirii trebuie să ceară ajutor medical de specialitate.")
                                .font(.system(size: 13, weight: .bold))
                                .fontWeight(.regular)
                                .multilineTextAlignment(.center)
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .offset(y: 130)
                            
                            ForEach(1..<20){ i in
                                Spacer()
                            }
                            
                            
                        }
                        
                            }
                        .frame(width: 300, height: 450)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white)
                        )
                        .offset(x: 60)
                        .zIndex(2)
                    
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
                        .offset(x: 60)
                        .zIndex(2)
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                }}
                .position(x: 195, y: -70)
                .zIndex(1)
            
            Link(destination: URL(string: "https://www.who.int/emergencies/diseases/novel-coronavirus-2019/question-and-answers-hub/q-a-detail/coronavirus-disease-covid-19#:~:text=symptoms")!){
                    HStack{
                        Image(systemName: "info.circle")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                            .padding(.leading, 20)
                            .padding(.trailing, 5)
                        
                        //Spacer()
                        VStack(alignment: .leading){
                            Text("Pentru mai multe informații accesează")
                                .font(.system(size: 14, weight: .regular))
                                .padding(.trailing, 20)
                                .foregroundColor(Color.black)
                            Text("www.who.int")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
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
        .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
    }
}

struct SimptomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SimptomeView()
        }
    }
}

struct Simptome : Identifiable{
    var id = UUID()
    var nume : String
    var descriere : String
    var image : String
}

let dataSimptome = [
    Simptome(nume: "Febră", descriere: "Febră peste 38 de grade (în 90% din cazuri)", image: "febra_Simptome"),
    Simptome(nume: "Tuse", descriere: "Tuse uscată (în 60% din cazuri)", image: "tuse_Simptome")
]

