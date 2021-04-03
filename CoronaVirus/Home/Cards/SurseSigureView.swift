//
//  SurseSigureView.swift
//  CoronaVirus
//
//  Created by Milovan on 30.03.2021.
//

import SwiftUI

struct SurseSigureView: View {
    @State var cards = cardsData
    
    var body: some View {
            VStack{
                HStack{
                    Text("Surse sigure")
                        .foregroundColor(Color.white)
                        .font(.system(size: 30, weight: .bold))
                        .offset(x: 30)
                        .offset(y: 20)
                    Spacer()
                    
                    Link(destination: URL(string: "https://vaccinare-covid.gov.ro/resurse/surse-oficiale-de-informare/")!){
                    Image(systemName: "info.circle")
                        .foregroundColor(Color.white)
                        .font(.system(size: 30, weight: .bold))
                        .offset(x: -20)
                        .offset(y: 20)
                    }
                }
                .frame(width: 395, height: 100)
                .background(Color(#colorLiteral(red: 0.9710895419, green: 0.8475009799, blue: 0.7614192367, alpha: 1)))
                
                ScrollView{
                    HStack{
                        cards[3].image
                            .resizable()
                            .frame(width: 400, height: 400)
                            .aspectRatio(contentMode: .fit)
                            .offset(y: 105)
                    }
                    .offset(y: -110)
        
                    VStack(spacing: 10){
                    ForEach(surseOficiale){ item in
                        Link(destination: URL(string: item.website)!){
                            SursaView(sursa: item)
                        }
                    }
                }
                    
                
            }
                .offset(y: -20)
        }
        .background(Color.white)
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }

struct SurseSigureView_Previews: PreviewProvider {
    static var previews: some View {
        SurseSigureView()
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
    Sursa(nume: "Vaccinuri anti-COVID-19 sigure în Europa", website: "https://ec.europa.eu/info/live-work-travel-eu/coronavirus-response/safe-covid-19-vaccines-europeans_ro", websitePrint: "www.ec.europa.eu", image: Image("eu"), color: Color(#colorLiteral(red: 0.147555232, green: 0.2898129225, blue: 0.6446350217, alpha: 1))),
    Sursa(nume: "Agenția Europeană a Medicamentului", website: "https://www.ema.europa.eu/en", websitePrint: "www.ema.europa.eu", image: Image("ema"), color: Color(#colorLiteral(red: 0.05977845937, green: 0.2519665956, blue: 0.5820891857, alpha: 1))),
    Sursa(nume: "Organizația Mondială \na Sănătății", website: "https://who.int", websitePrint: "www.who.int", image: Image("who"), color: Color(#colorLiteral(red: 0.1968083084, green: 0.5436140895, blue: 0.8174911141, alpha: 1))),
    /*Sursa(nume: "Conduită sanitară", website: "https://stirioficiale.ro/conduita", image: Image("placeholder")),
    Sursa(nume: "Conduită sanitară", website: "https://stirioficiale.ro/conduita", image: Image("placeholder")),
    Sursa(nume: "Conduită sanitară", website: "https://stirioficiale.ro/conduita", image: Image("placeholder")),
    Sursa(nume: "Conduită sanitară", website: "https://stirioficiale.ro/conduita", image: Image("placeholder"))*/
]

struct SursaView: View {
    
    var sursa : Sursa
    
    var body : some View {
        HStack{
            sursa.image
                .resizable()
                .frame(width: 70, height: 70)
                .background(Color.white)
                .cornerRadius(10)
                //.offset()
            
            //Spacer()
            
            VStack {
                Text(sursa.nume)
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Color.black)
                    .aspectRatio(contentMode: .fit)
                    .padding(.trailing, 14)
                
                Spacer()
                
                Text(sursa.websitePrint)
            }
        }
        .frame(width: 355, height: 80)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        )
    }
}}
