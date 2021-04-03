//
//  DocumenteUtileView.swift
//  CoronaVirus
//
//  Created by Milovan on 31.03.2021.
//

import SwiftUI
import Swift
import SwiftUITrackableScrollView


struct DocumenteUtileView: View {
    
    @State var showDocumentActions = false
    @State private var scrollViewContentOffset = CGFloat(0) //80
    @State var elementOpacity : Double = 0
    
    var body: some View {
        
        ZStack {
                VStack{
                    Text("Documente utile")
                        .foregroundColor(Color.white)
                        .font(.system(size: 30, weight: .bold))
                        .offset(y: 70)
                        .offset(x: -50)
                        .frame(width: 400)
                        .opacity(0.01 * Double(scrollViewContentOffset))
                        
                    
                    Link(destination: URL(string: "https://cetrebuiesafac.ro/modele-declaratii")!){
                        HStack{
                            Image(systemName: "info.circle")
                                .font(.system(size: 13, weight: .bold))
                                .offset(x: 90)
                                .foregroundColor(Color.black)
                                .opacity(0.01 * Double(scrollViewContentOffset))
                            
                            Text("Pentru mai multe informații accesează www.cetrebuiesafac.ro")
                                .font(.system(size: 10, weight: .bold))
                                .offset(x: 90)
                                .foregroundColor(Color.black)
                                .opacity(0.01 * Double(scrollViewContentOffset))
                        }
                        .frame(width: 550, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(#colorLiteral(red: 0.6870401502, green: 0.8114628196, blue: 0.9983285069, alpha: 1))))
                        .offset(x: -87)
                        .offset(y: 71)
                    }
                    .opacity(0.01 * Double(scrollViewContentOffset))
                }
                .background(Rectangle() .fill(Color(#colorLiteral(red: 0, green: 0.4227619767, blue: 0.890914619, alpha: 1)).opacity(0.01 * Double(scrollViewContentOffset))) .offset(y: 50) .frame(height: 120))
                .offset(y: -420)
                .zIndex(2)
                .animation(Animation.easeInOut(duration: 4))
            
            TrackableScrollView(.vertical, showIndicators: false, contentOffset: $scrollViewContentOffset){
                
                    VStack{
                        Text("Documente utile")
                            .foregroundColor(Color.white)
                            .font(.system(size: 30, weight: .bold))
                            .offset(y: 70)
                            .offset(x: -50)
                            .frame(width: 400)
                            .opacity(1 - 0.02 * Double(scrollViewContentOffset))
                            
                        
                        Link(destination: URL(string: "https://cetrebuiesafac.ro/modele-declaratii")!){
                            HStack{
                                Image(systemName: "info.circle")
                                    .font(.system(size: 13, weight: .bold))
                                    .offset(x: 90)
                                    .foregroundColor(Color.black)
                                    .opacity(1 - 0.02 * Double(scrollViewContentOffset))
                                
                                Text("Pentru mai multe informații accesează www.cetrebuiesafac.ro")
                                    .font(.system(size: 10, weight: .bold))
                                    .offset(x: 90)
                                    .foregroundColor(Color.black)
                                    .opacity(1 - 0.02 * Double(scrollViewContentOffset))
                            }
                            .frame(width: 550, height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(#colorLiteral(red: 0.6870401502, green: 0.8114628196, blue: 0.9983285069, alpha: 1)).opacity(1 - 0.02 * Double(scrollViewContentOffset))))
                            .offset(x: -87)
                            .offset(y: 71)
                        }
                    }
                    .offset(y: 40)
                
                VStack{
                    
                    Text("Declarația pe propria răspundere")
                        .frame(width: 350)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.white)
                        .offset(y: 40)
                        .offset(x: -30)
                    
                        ForEach(documentDPRData){ item in
                            Button(action: {self.showDocumentActions.toggle()}, label: {
                                DocumentCardView(documentData: item, showDocumentActions: showDocumentActions ? true : false)
                                    .offset(y: -150)
                            })
                        }
                        
                        
                        Text("Adeverință de angajator")
                            .frame(width: 350)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.white)
                            .offset(y: 50)
                            .offset(x: -70)
                        
                        ForEach(documentAAData){ item in
                                DocumentCardView(documentData: item, showDocumentActions: true)
                                    .offset(y: -150)
                        }
                    
                    
                    ForEach(1..<45){ i in
                        Spacer()
                    }
                }
                .frame(width: 400)
                .background(
                    RoundedRectangle(cornerRadius: 38)
                        .fill(Color(#colorLiteral(red: 0.3783457875, green: 0.6356819868, blue: 0.9972093701, alpha: 1)).opacity(0.8)))
                .offset(y: 300)
            }
                .background(Image("documenteUtile").aspectRatio(contentMode: .fill).offset(y: 10).offset(x: 280))
                .frame(width: screen.width)
                .edgesIgnoringSafeArea(.all)
            .offset(x: -80)
                .zIndex(1)
        }
        .edgesIgnoringSafeArea(.all)
    }
    
}

struct DocumenteUtileView_Previews: PreviewProvider {
    static var previews: some View {
        DocumenteUtileView()
    }
}

struct DocumentCardView: View {
    
    var documentData : Document
    
    var showDocumentActions : Bool
    
    var body: some View {
        VStack(){
            
            HStack {
                documentData.imagine
                    .resizable()
                    .frame(width: 250, height: 170)
                    .offset(y: -10)
            }
            .frame(width: 350, height: 190)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(#colorLiteral(red: 0.8402631879, green: 0.902616322, blue: 0.9990279078, alpha: 1)))
                    .offset(y: -20)
            )
            
            if showDocumentActions {
                HStack(spacing: 20){
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
            }
            
            
            Text(documentData.titlu)
                .foregroundColor(Color.white)
                .font(.system(size: 16, weight: .bold))
                .offset(y: -10)
                
            
        }
        .frame(width: 350, height: 230)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(#colorLiteral(red: 0.6870401502, green: 0.8114628196, blue: 0.9983285069, alpha: 1))))
        .offset(y: showDocumentActions ? 310 : 220)
        .padding(.bottom, showDocumentActions ? -30 : 30)
    }
}

struct Document : Identifiable {
    var id = UUID()
    var titlu : String
    var imagine : Image
}

let documentDPRData = [
    Document(titlu: "Indiferent de rata de incidență", imagine: Image("document1")),
    Document(titlu: "Rată de incidență > 4% sau 7,5%", imagine: Image("document2")),
    Document(titlu: "Tranzitarea unei localități carantinate", imagine: Image("document5"))
]

let documentAAData = [
    Document(titlu: "Indiferent de rata de incidență", imagine: Image("document3")),
    Document(titlu: "Rată de incidență > 4% sau 7,5%", imagine: Image("document4"))
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
