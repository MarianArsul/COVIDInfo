//
//  News.swift
//  CoronaVirus
//
//  Created by Milovan on 01.05.2021.
//

import SwiftUI
import PartialSheet
import SwiftSoup

struct Article : Identifiable {
    var id = UUID()
    var data : String
    var autor: String
    var link : String
    var titlu: String
    var descriere: String
    var vaccinare: Bool
}

var articleData = [Article]()

let url = URL(string: "https://stirioficiale.ro/informatii")!

func articlePresentedScrape(){
    do{
        let html = try String(contentsOf: url)
        let document : Elements = try SwiftSoup.parse(html).select("article")

        for article : Element in document.array(){
            var data = Article(data: "", autor: "", link: "", titlu: "", descriere: "", vaccinare: false)
            
            data.data = try article.select("span").first()!.text()
            
            let spans : Elements = try article.select("span")
            for span : Element in spans.array(){
                data.autor = try span.text()
            }
            
            let link : Element = try article.select("a").first()!
            data.link = try link.attr("href")
            data.titlu = try link.text()
            
            let ps : Elements = try article.select("p")
            var string = ""
            for desc : Element in ps.array(){
                string += try desc.text()
            }
            data.descriere = string
            
            if data.titlu.contains("vaccinate"){
                data.vaccinare = true
            }
            
            articleData.append(data)
        }
    }catch Exception.Error(let type, let message) {
        print(message, type)
    } catch {
        print("error")
    }
}

struct News : View{
    
    @State var article : Article
    
    var body: some View{
         ZStack(alignment: .bottom){
            Image(article.vaccinare ? "news1" : "news2")
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(width: 200, height: 250)
                 .accessibility(hidden: true)
                .offset(y: -20)
             
             HStack {
                 VStack(alignment: .leading) {
                     Text(article.titlu)
                         .font(.system(size: 20, weight: .bold))
                         .foregroundColor(Color(#colorLiteral(red: 0.1024787799, green: 0.1775858402, blue: 0.2037084699, alpha: 1)))
                 }
                 Spacer()
             }
             .padding()
             //.frame(width: 250, hieght:)
             .accessibilityElement(children: .combine)
             .background(VisualEffectBlur())
         }
         .background(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1)))
         .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
         //.shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
         .padding()
         .accessibilityElement(children: .contain)
        
    }
}


struct News_Previews: PreviewProvider {
    static var previews: some View {
        News(article: articleData[0])
    }
}

