//
//  NewsExtended1.swift
//  CoronaVirus
//
//  Created by Milovan on 03.05.2021.
//

import SwiftUI
import PartialSheet
import SwiftSoup

struct Doza : Identifiable {
    var id = UUID()
    var tipVaccin: String
    var inUltimele24h: String
    var din27Decembrie2020: String
}

var dozeAdministrate = [Doza]()
var image : String = ""

func newsExtendedOne(url: String){
    let urlArticol = URL(string: url)!
    do{
        let html = try String(contentsOf: urlArticol)
        let document : Elements = try SwiftSoup.parse(html).select("main")
        let div : Element = try document.select("div.my-8").first()!
        image = try div.select("img").attr("src")

        let tabel = try SwiftSoup.parse(html).select("tbody")

        for row : Element in try tabel.array(){
            let tr = try row.select("tr")
            for td : Element in try tr.array(){
                var doza = Doza(tipVaccin: "", inUltimele24h: "", din27Decembrie2020: "")
                let td = try td.select("td")
                var index = 0
                for element : Element in try td.array(){
                    if index == 0 {doza.tipVaccin = try element.text()}
                    if index == 1 {doza.inUltimele24h = try element.text()}
                    if index == 2 {doza.din27Decembrie2020 = try element.text()}
                    index += 1
                }
                dozeAdministrate.append(doza)
            }
        }
    }catch Exception.Error(let type, let message) {
        print(message, type)
    } catch {
        print("error")
    }
    
    dozeAdministrate.remove(at: 0)
}

let text = "Conform Rezumatului Caracteristicilor Produsului (RCP), reacțiile adverse raportate sunt enumerate în funcție de următoarea convenție privind frecvența: \n • Foarte frecvente (≥1/10)  Frecvente (≥1/100 și <1/10) ; \n • Mai puțin frecvente (≥1/1.000 și <1/100); \n • Rare (≥1/10000 și <1/1.000); \n • Foarte rare (<1/10.000). \n\nPrecizăm că programul centrelor de vaccinare se încheie la ora 20.00, motiv pentru care numărul vaccinărilor realizate în intervalul orar 17.00 – 20.00 va fi reflectat în raportarea din ziua următoare."

struct NewsExtended1 : View {
    
    @State var article : Article
    
    var body : some View{
        ScrollView(.vertical, showsIndicators: false){
            Text(article.titlu)
                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                .foregroundColor(Color.black)
                .font(.system(size: 25, weight: .bold))
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 20)
            
            HStack{
                Text(article.data)
                Text("•")
                Text(article.autor)
                Spacer()
            }
            .font(.system(size: 18, weight: .bold))
            .padding(.top)
            .padding(.leading, 30)
            
            Link(destination: URL(string: article.link)!) {
                HStack{
                    Text("Sursa: www.stirioficiale.ro")
                    Image(systemName: "arrow.right")
                    Spacer()
                }
                .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                .font(.system(size: 15, weight: .bold))
                .padding(.leading, 30)
                .offset(y: 3)
            }
            
            Text(article.descriere)
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 30)
                .padding(.bottom, 10)
                .foregroundColor(Color.black)
                .font(.system(size: 15))
            
            Text("Persoane vaccinate:")
                .font(.system(size: 13, weight: .bold))
                .offset(x: -106)
            
            AsyncImage(url: URL(string: image)!,placeholder: { Text("Se incarca...") },image: { Image(uiImage: $0).resizable() })
                .frame(width: 350, height: 200)
                
            Text("Doze administrate:")
                .font(.system(size: 13, weight: .bold))
                .offset(x: -113)
                .padding(.top, 10)
            
            VStack(spacing: 10){
                ForEach(dozeAdministrate){item in
                    HStack{
                        Image(item.tipVaccin)
                            .resizable()
                            .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                            .frame(width: 100, height: 100)
                        
                        VStack(alignment: .leading){
                            Text(item.tipVaccin)
                                .offset(y: -10)
                                .foregroundColor(Color.black)
                                .font(.system(size: 15, weight: .bold))
                            
                            Text("In ultimele 24 ore: \(item.inUltimele24h) doze")
                                .foregroundColor(Color.black)
                                .font(.system(size: 15))
                                .padding(.trailing, 20)
                            
                            Text("Din 27 decembrie 2020: \(item.din27Decembrie2020) doze")
                                .foregroundColor(Color.black)
                                .font(.system(size: 15))
                                .padding(.trailing, 20)
                        }
                        .offset(x: 20)
                        
                        Spacer()
                    }
                    .padding(.leading, 20)
                    
                    HStack{
                        
                    }
                    .frame(width: 350, height: 1)
                    .background(Color(#colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)))
                }
            }
            
            Text(text)
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 30)
                .padding(.bottom, 10)
                .foregroundColor(Color.black)
                .font(.system(size: 15))
        }
    }
}


