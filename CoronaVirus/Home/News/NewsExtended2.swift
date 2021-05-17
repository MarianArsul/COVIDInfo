//
//  NewsExtended2.swift
//  CoronaVirus
//
//  Created by Milovan on 03.05.2021.
//

import SwiftSoup
import Foundation
import SwiftUI

struct Tabel1 : Identifiable {var id = UUID(); var nr : String; var judet: String; var nrCazConfirTotal: String; var nrCazNouConfir: String; var incidenta: String;}
var tabel1 = [Tabel1]()

struct Tabel2 : Identifiable {var id = UUID(); var nr: String; var judet: String; var probeTabel2: String;}
var tabel2 = [Tabel2]()
var totalRetestari = 0

struct Tabel3 : Identifiable {var id = UUID(); var tara: String; var cazuriConfirmate: String; var decedati: String; var vindecati: String}
var tabel3 = [Tabel3]()

struct Tabel4 : Identifiable {var id = UUID(); var cazuriConfirmate : String; var decedati: String; var vindecati: String
}
var tabel4 = [Tabel4]()
var paragraphs = [String]()

func newsExtendedTwo(url: String){
    let urlArticol = URL(string: url)!
    do{
        let html = try String(contentsOf: urlArticol)
        let div : Element = try SwiftSoup.parse(html).select("div.my-8").first()!
        let table = try div.select("table")

        let firstParagraph = try div.select("p").first()!.text()

        let tbody = try table.select("tbody")

        var tableIndex = 1
        for table : Element in try tbody.array(){
            for tr : Element in try table.select("tr"){
                if tableIndex == 1{
                    var cazuri : Tabel1 = Tabel1(nr: "", judet: "", nrCazConfirTotal: "", nrCazNouConfir: "", incidenta: "")
                    let td = try tr.select("td")
                    var index = 0
                    for p : Element in try td.select("p"){
                        if index == 0 {cazuri.nr = try p.text()}
                        if index == 1 {cazuri.judet = try p.text()}
                        if index == 2 {cazuri.nrCazConfirTotal = try p.text()}
                        if index == 3 {cazuri.nrCazNouConfir = try p.text()}
                        if index == 4 {cazuri.incidenta = try p.text()}
                        index += 1
                    }
                    tabel1.append(cazuri)
                }
                
                if tableIndex == 2 {
                    var ret : Tabel2 = Tabel2(nr: "", judet: "", probeTabel2: "")
                    let td = try tr.select("td")
                    var index = 0
                    for p : Element in try td.select("p"){
                        if index == 0 {ret.nr = try p.text()}
                        if index == 1 {ret.judet = try p.text()}
                        if index == 2 {ret.probeTabel2 = try p.text()}
                        index += 1
                    }
                    tabel2.append(ret)
                }
                
                if tableIndex == 3 {
                    var tabel31 : Tabel3 = Tabel3(tara: "", cazuriConfirmate: "", decedati: "", vindecati: "")
                    let td = try tr.select("td")
                    var index = 0
                    for p : Element in try td.select("p"){
                        if index == 0 {tabel31.tara = try p.text()}
                        if index == 1 {tabel31.cazuriConfirmate = try p.text()}
                        if index == 2 {tabel31.decedati = try p.text()}
                        if index == 3 {tabel31.vindecati = try p.text()}
                        index += 1
                    }
                    tabel3.append(tabel31)
                }
                
                if tableIndex == 4 {
                    var tabel41 : Tabel4 = Tabel4(cazuriConfirmate: "", decedati: "", vindecati: "")
                    let td = try tr.select("td")
                    var index = 0
                    for p : Element in try td.select("p"){
                        if index == 0 {tabel41.cazuriConfirmate = try p.text()}
                        if index == 1 {tabel41.decedati = try p.text()}
                        if index == 2 {tabel41.vindecati = try p.text()}
                        index += 1
                    }
                    tabel4.append(tabel41)
                }
            }
            tableIndex += 1
        }
        let ps = try div.select("p")
        var paragraphIndex = 1

        for p: Element in try ps.array(){
            if paragraphIndex == 1 {paragraphs.append(try p.text())}
            if (paragraphIndex >= 229) && (paragraphIndex <= 236) {paragraphs.append(try p.text())}
            if (paragraphIndex >= 370) && (paragraphIndex <= 401) {paragraphs.append(try p.text())}
            if (paragraphIndex >= 443) && (paragraphIndex <= 446) {paragraphs.append(try p.text())}
            
            paragraphIndex += 1
        }
    }catch Exception.Error(let type, let message) {
        print(message, type)
    } catch {
        print("error")
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
        }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct NewsExtended2: View {
    
    @State var article: Article
    @State private var orientation = UIDeviceOrientation.unknown
    
    var body: some View {
        ScrollView(.vertical){
            VStack(spacing: 10){
                Text(article.titlu)
                    .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                    .foregroundColor(Color.black)
                    .font(.system(size: 25, weight: .bold))
                
                HStack{
                    Text(article.data)
                        .offset(y: -9)
                    Text("•")
                        .offset(y: -10)
                    Text(article.autor)
                    Spacer()
                }
                .font(.system(size: 15, weight: .bold))
                .offset(x: 25)
                //.padding(.leading, 20)
                //.padding(.trailing, 20)
                
                Link(destination: URL(string: article.link)!) {
                    HStack{
                        Text("Sursa: www.stirioficiale.ro")
                        Image(systemName: "arrow.right")
                        Spacer()
                    }
                    .foregroundColor(Color(#colorLiteral(red: 0.8941176471, green: 0.3254901961, blue: 0.3607843137, alpha: 1)))
                    .font(.system(size: 15, weight: .bold))
                }
                .offset(x: 26)
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .offset(y: 20)
            
            Text(paragraphs[0])
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 50)
                .padding(.bottom, 10)
                .foregroundColor(Color.black)
                .font(.system(size: 15))
            
            Group {
                if orientation.isPortrait {
                    ZStack{
                        Image("tabel")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                        Text("Rotiti dispozitivul pentru a vedea continutul")
                            .frame(width: 350, height: 250)
                            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.black.opacity(0.2)))
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 350, height: 250)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color(#colorLiteral(red: 0.982924521, green: 0.9290560484, blue: 0.9331017137, alpha: 1))))
                }
                else if orientation.isLandscape {
                    VStack(spacing: 10){
                        ForEach(tabel1){item in
                            HStack{
                                Text(item.nr)
                                    .frame(width: screen.width/5)
                                Text(item.judet)
                                    .frame(width: screen.width/5)
                                Text(item.nrCazConfirTotal)
                                    .frame(width: screen.width/5)
                                Text(item.nrCazNouConfir)
                                    .frame(width: screen.width/5)
                                Text(item.incidenta)
                                    .frame(width: screen.width/5)
                            }
                            .background(Color(#colorLiteral(red: 0.9802891612, green: 0.9804531932, blue: 0.9802660346, alpha: 1)))
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                }
                else {
                    ZStack{
                        Image("tabel")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                        Text("Rotiti dispozitivul pentru a vedea continutul")
                            .offset(y: -80)
                            .frame(width: 350, height: 250)
                            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.black.opacity(0.2)))
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 350, height: 250)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color(#colorLiteral(red: 0.982924521, green: 0.9290560484, blue: 0.9331017137, alpha: 1))))
                }
            }
            .onRotate { newOrientation in
                orientation = newOrientation
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.bottom, 10)
            .foregroundColor(Color.black)
            .font(.system(size: 15, weight: .bold))
            
            Text(paragraphs[2])
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.bottom, 10)
                .foregroundColor(Color.black)
                .font(.system(size: 15))
            
            Text(paragraphs[4])
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.bottom, 10)
                .foregroundColor(Color.black)
                .font(.system(size: 15))
                .offset(x: -4)
            
            Group {
                if orientation.isPortrait {
                    ZStack{
                        Image("tabel")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                        Text("Rotiti dispozitivul pentru a vedea continutul")
                            .frame(width: 350, height: 250)
                            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.black.opacity(0.2)))
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 350, height: 250)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color(#colorLiteral(red: 0.982924521, green: 0.9290560484, blue: 0.9331017137, alpha: 1))))
                }
                else if orientation.isLandscape {
                    VStack(spacing: 10){
                        ForEach(tabel2){item in
                            HStack{
                                Text(item.nr)
                                    .frame(width: screen.width/3)
                                Text(item.judet)
                                    .frame(width: screen.width/3)
                                Text(item.probeTabel2)
                                    .frame(width: screen.width/3)
                            }
                            .background(Color(#colorLiteral(red: 0.9802891612, green: 0.9804531932, blue: 0.9802660346, alpha: 1)))
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                }
                else {
                    ZStack{
                        Image("tabel")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                        Text("Rotiti dispozitivul pentru a vedea continutul")
                            .offset(y: -80)
                            .frame(width: 350, height: 250)
                            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.black.opacity(0.2)))
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 350, height: 250)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color(#colorLiteral(red: 0.982924521, green: 0.9290560484, blue: 0.9331017137, alpha: 1))))
                }
            }
            .onRotate { newOrientation in
                orientation = newOrientation
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.bottom, 10)
            .foregroundColor(Color.black)
            .font(.system(size: 15, weight: .bold))
            
            ForEach(10..<41){item in
                Text("\(paragraphs[item])")
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .foregroundColor(Color.black)
                    .font(.system(size: 15))
            }
            
            Group {
                if orientation.isPortrait {
                    ZStack{
                        Image("tabel")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                        Text("Rotiti dispozitivul pentru a vedea continutul")
                            .frame(width: 350, height: 250)
                            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.black.opacity(0.2)))
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 350, height: 250)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color(#colorLiteral(red: 0.982924521, green: 0.9290560484, blue: 0.9331017137, alpha: 1))))
                }
                else if orientation.isLandscape {
                    VStack(spacing: 10){
                        ForEach(tabel3){item in
                            HStack{
                                Text(item.tara)
                                    .frame(width: screen.width/4)
                                Text(item.cazuriConfirmate)
                                    .frame(width: screen.width/4)
                                Text(item.decedati)
                                    .frame(width: screen.width/4)
                                Text(item.vindecati)
                                    .frame(width: screen.width/4)
                            }
                            .background(Color(#colorLiteral(red: 0.9802891612, green: 0.9804531932, blue: 0.9802660346, alpha: 1)))
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                }
                else {
                    ZStack{
                        Image("tabel")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                        Text("Rotiti dispozitivul pentru a vedea continutul")
                            .offset(y: -80)
                            .frame(width: 350, height: 250)
                            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.black.opacity(0.2)))
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 350, height: 250)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color(#colorLiteral(red: 0.982924521, green: 0.9290560484, blue: 0.9331017137, alpha: 1))))
                }
            }
            .onRotate { newOrientation in
                orientation = newOrientation
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.bottom, 10)
            .foregroundColor(Color.black)
            .font(.system(size: 15, weight: .bold))
            
            Text("Situatie globala la \(article.data)")
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .foregroundColor(Color.black)
                .font(.system(size: 15))
                .offset(x: -70)
            
            Group {
                if orientation.isPortrait {
                    ZStack{
                        Image("tabel")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                        Text("Rotiti dispozitivul pentru a vedea continutul")
                            .frame(width: 350, height: 250)
                            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.black.opacity(0.2)))
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 350, height: 250)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color(#colorLiteral(red: 0.982924521, green: 0.9290560484, blue: 0.9331017137, alpha: 1))))
                }
                else if orientation.isLandscape {
                    VStack(spacing: 10){
                        ForEach(tabel4){item in
                            HStack{
                                Text(item.cazuriConfirmate)
                                    .frame(width: screen.width/3)
                                Text(item.decedati)
                                    .frame(width: screen.width/3)
                                Text(item.vindecati)
                                    .frame(width: screen.width/3)
                            }
                            .background(Color(#colorLiteral(red: 0.9802891612, green: 0.9804531932, blue: 0.9802660346, alpha: 1)))
                        }
                    }
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                }
                else {
                    ZStack{
                        Image("tabel")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                        
                        Text("Rotiti dispozitivul pentru a vedea continutul")
                            .offset(y: -80)
                            .frame(width: 350, height: 250)
                            .background(RoundedRectangle(cornerRadius: 20) .fill(Color.black.opacity(0.2)))
                            .foregroundColor(Color.black)
                    }
                    .frame(width: 350, height: 250)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color(#colorLiteral(red: 0.982924521, green: 0.9290560484, blue: 0.9331017137, alpha: 1))))
                }
            }
            .onRotate { newOrientation in
                orientation = newOrientation
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .padding(.bottom, 10)
            .foregroundColor(Color.black)
            .font(.system(size: 15, weight: .bold))
            
            
        }
    }
}

struct NewsExtended2_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NewsExtended2(article: articleData[0])
        }
    }
}

