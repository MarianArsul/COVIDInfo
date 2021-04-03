//
//  DocumenteUtileView.swift
//  CoronaVirus
//
//  Created by Milovan on 31.03.2021.
//

import SwiftUI

struct DocumenteUtileView: View {
    
    var body: some View {
        ScrollView(showsIndicators: false){
            
            Text("Documente utile")
                .foregroundColor(Color.white)
                .font(.system(size: 30, weight: .bold))
                .offset(y: 70)
                .offset(x: -50)
                .frame(width: 400)
            
            Link(destination: URL(string: "https://cetrebuiesafac.ro/modele-declaratii")!){
                HStack{
                    Image(systemName: "info.circle")
                        .font(.system(size: 13, weight: .bold))
                        .offset(x: 90)
                        .foregroundColor(Color.black)
                    
                    Text("Pentru mai multe informații accesează www.cetrebuiesafac.ro")
                        .font(.system(size: 10, weight: .bold))
                        .offset(x: 90)
                        .foregroundColor(Color.black)
                }
                .frame(width: 550, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(#colorLiteral(red: 0.6870401502, green: 0.8114628196, blue: 0.9983285069, alpha: 1))))
                .offset(x: -87)
                .offset(y: 71)
            }
            VStack{
                
                Text("Declarația pe propria răspundere")
                    .frame(width: 350)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.white)
                    .offset(y: 40)
                    .offset(x: -30)
                
                VStack(spacing: 20){
                    ForEach(documentDPRData){ item in
                        DocumentCardView(documentData: item)
                            .offset(y: -150)
                    }
                    
                    Text("Adeverință de angajator")
                        .frame(width: 350)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.white)
                        .offset(y: 70)
                        .offset(x: -70)
                    
                    ForEach(documentAAData){ item in
                        DocumentCardView(documentData: item)
                            .offset(y: -120)
                    }
                }
                
                ForEach(1..<45){ i in
                    Spacer()
                }
            }
            .frame(width: 400)
            .background(
                RoundedRectangle(cornerRadius: 38)
                    .fill(Color(#colorLiteral(red: 0.3783457875, green: 0.6356819868, blue: 0.9972093701, alpha: 1)).opacity(0.8)))
            .offset(y: 250)
        }
            .background(Image("documenteUtile").aspectRatio(contentMode: .fill).offset(y: 10).offset(x: 280))
        .frame(width: screen.width)
    }
    
}

struct DocumenteUtileView_Previews: PreviewProvider {
    static var previews: some View {
        DocumenteUtileView()
    }
}

struct DocumentCardView: View {
    
    var documentData : Document
    
    var body: some View {
        VStack(){
            documentData.imagine
                .resizable()
                .frame(width: 350, height: 210)
                .cornerRadius(20)
                .offset(y: -15)
                .zIndex(1)
            
            /*HStack(spacing: 20){
                ForEach(0..<3){ i in
                    VStack {
                        Image(systemName: documentActionsData[i].icon)
                            .font(.system(size: 40, weight: .bold))
                            .frame(width: 80, height: 70)
                            .background(Circle().fill(Color.white))
                            .foregroundColor(Color(#colorLiteral(red: 0.6870401502, green: 0.8114628196, blue: 0.9983285069, alpha: 1)))
                        
                        Text(documentActionsData[i].action)
                            .foregroundColor(Color.white)
                            .font(.system(size: 15, weight: .bold))
                            .offset(y: 10)
                    }
                    .zIndex(3)
                }
            }
            .frame(width: 350, height: 210)
            .background(Color.white.opacity(0.1).blur(radius: 30))
            .offset(y: -230)
            .zIndex(2)*/
            
            
            Text(documentData.titlu)
                .foregroundColor(Color.white)
                .font(.system(size: 16, weight: .bold))
                .offset(y: -10)
                
            
        }
        .frame(width: 350, height: 250)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(#colorLiteral(red: 0.6870401502, green: 0.8114628196, blue: 0.9983285069, alpha: 1))))
        .offset(y: 210)
        .zIndex(1)
    }
}

struct Document : Identifiable {
    var id = UUID()
    var titlu : String
    var imagine : Image
}

let documentDPRData = [
    Document(titlu: "Indiferent de rata de incidență", imagine: Image("imagePlaceholder")),
    Document(titlu: "Rată de incidență > 4% sau 7,5%", imagine: Image("imagePlaceholder"))
]

let documentAAData = [
    Document(titlu: "Indiferent de rata de incidență", imagine: Image("imagePlaceholder")),
    Document(titlu: "Rată de incidență > 4% sau 7,5%", imagine: Image("imagePlaceholder"))
]

struct DocumentActions : Identifiable{
    var id = UUID()
    var icon : String
    var action : String
}

let documentActionsData = [
    DocumentActions(icon: "pencil.circle", action: "Editare"),
    DocumentActions(icon: "eye.circle", action: "Vizualizare"),
    DocumentActions(icon: "arrow.down.circle", action: "Descărcare")
]
