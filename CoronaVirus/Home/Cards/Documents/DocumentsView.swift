//
//  DocumentsView.swift
//  CoronaVirus
//
//  Created by Milovan on 09.04.2021.
//

import SwiftUI
import SwiftUITrackableScrollView

enum documentSheets : Identifiable {
    var id: Int {
        self.hashValue
    }
    
    case sheet0
    case sheet1
    case sheet2
    case sheet3
    case sheet4
}

struct DocumentsView: View {
    
    @State private var scrollViewContentOffset = CGFloat(0)
    @State private var showIntroDocumentActions = false
    @State private var documents = documentData
    @State private var activeDocumentSheet: documentSheets?
    
    var body: some View{
        
        ZStack {
            HStack{
                Text("Documente")
                    .font(.system(size: 25, weight: .bold))
                    .offset(y: 30)
                    .opacity(scrollViewContentOffset > 55 ? Double(0.01 * scrollViewContentOffset) : 0)
            }
            .frame(width: screen.width, height: 120)
            .background(Color(#colorLiteral(red: 0.9218111634, green: 0.9173565507, blue: 0.9369328618, alpha: 1)))
            .offset(y: -400)
            .zIndex(2)
            
            TrackableScrollView(.vertical, showIndicators: false, contentOffset: $scrollViewContentOffset) {
                
                //TITLU
                
                HStack{
                    Text("Documente")
                        .font(.system(size: 30, weight: .bold))
                        .offset(y: 120)
                    
                    Spacer()
                    
                    Image(systemName: "info.circle")
                        .font(.system(size: 30, weight: .bold))
                        .offset(y: 120)
                }
                .padding(.leading, 30)
                .padding(.trailing, 30)
                .zIndex(1)
                
                //DOCUMENTE UTILIZATOR
                
                ScrollView(.horizontal, showsIndicators: false){
                    HStack(spacing: 50){
                        Button(action: {self.showIntroDocumentActions.toggle()}, label: {
                            IntroDocumente(showIntroDocumentActions: $showIntroDocumentActions)
                                .offset(x: 30)
                        })
                        .foregroundColor(Color.black)
                        
                        DocumenteUtilizator()
                    }
                }
                .frame(height: 450)
                .offset(y: 130)
                
                //DECLARATII
                
                VStack(spacing: 20){
                    Text("Indiferent de rata de incidență")
                        .font(.system(size: 20, weight: .bold))
                        .offset(x: -20)
                    
                    Button(action: {activeDocumentSheet = .sheet0}){
                        ListaDocumente(document: documents[0])
                    }
                    .foregroundColor(Color.black)
                    
                    Button(action: {activeDocumentSheet = .sheet1}){
                        ListaDocumente(document: documents[1])
                    }
                    .foregroundColor(Color.black)
                    
                    Text("Rată de incidență mai mare de 4%, respectiv 7,5%")
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(/*@START_MENU_TOKEN@*/.leading/*@END_MENU_TOKEN@*/)
                        
                    
                    Button(action: {activeDocumentSheet = .sheet2}){
                        ListaDocumente(document: documents[2])
                    }
                    .foregroundColor(Color.black)
                    
                    Button(action: {activeDocumentSheet = .sheet3}){
                        ListaDocumente(document: documents[3])
                    }
                    .foregroundColor(Color.black)
                    
                    Text("Tranzitarea unei localități carantinate")
                        .font(.system(size: 19, weight: .bold))
                    
                    Button(action: {activeDocumentSheet = .sheet4}){
                        ListaDocumente(document: documents[4])
                    }
                    .foregroundColor(Color.black)
                }
                .sheet(item: $activeDocumentSheet){ item in
                    switch item{
                        case .sheet0:
                            DocumentDetails(document: documents[0])
                        case .sheet1:
                            DocumentDetails(document: documents[1])
                        case .sheet2:
                            DocumentDetails(document: documents[2])
                        case .sheet3:
                            DocumentDetails(document: documents[3])
                        case .sheet4:
                            DocumentDetails(document: documents[4])
                    }
                }
                .offset(y: 140)
                
                ForEach(0..<30){item in
                    Spacer()
                }
            }
            .frame(width: screen.width, height: screen.height)
            .background(Color(#colorLiteral(red: 0.9218111634, green: 0.9173565507, blue: 0.9369328618, alpha: 1)))
        }
    }
}

struct DocumentsView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentsView()
    }
}

struct IntroDocumente : View {
    
    @Binding var showIntroDocumentActions : Bool
    @State var showIntroDocument = true
    
    var body : some View {
    
        if showIntroDocument  == true {
            ZStack(alignment: .leading){
                Image(systemName: "doc.text")
                    .font(.system(size: 40, weight: .bold))
                    .offset(y: -150)
                
                VStack(alignment: .leading) {
                    Text("Aici vor aparea documentele tale")
                        .font(.system(size: 20, weight: .bold))
                        .padding(.bottom, 2)
                
                    Text("Poti sa completezi documentele direct din aplicatie")
                        .font(.system(size: 15, weight: .bold))
                        .padding(.bottom, 3)
                    
                    Text("Documentele pot fi salvate direct in aplicatie ca sa scapi de griji")
                        .font(.system(size: 10, weight: .bold))
                }
                .offset(y: 110)
                
                if showIntroDocumentActions == true{
                    Button(action: {self.showIntroDocument.toggle()}, label: {
                        VStack{
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundColor(Color.red)
                                .padding(.bottom, 10)
                            
                            Text("Inchide")
                                .font(.system(size: 20, weight: .bold))
                        }
                        .frame(width: 230, height: 430)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(0.9)))
                    })
                }
            }
            .frame(width: 230, height: 430)
            .padding(.leading, 20)
            .padding(.trailing, 20)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
        }
    }
}

struct DocumenteUtilizator : View {
    
    var body : some View{
        ZStack{
            Image("declaratie1")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .offset(y: -20)
            
            Text("Titlu")
                .font(.system(size: 23, weight: .bold))
                .offset(y: 140)
                .offset(x: -90)
            
            Text("Tip: Indiferent de rata de incidenta")
                .font(.system(size: 13, weight: .regular))
                .offset(y: 162)
                .offset(x: -7)
            
            Text("Data: 09/04/2021")
                .font(.system(size: 10, weight: .regular))
                .offset(y: 178)
                .offset(x: -68)
            
        }
        .frame(width: 230, height: 430)
        .padding(.leading, 20)
        .padding(.trailing, 20)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
    }
}

struct ListaDocumente : View {
    
    @State var document : Declaratie
    var body: some View{
        
        ZStack{
            Image("pdfIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(.top, 15)
                .padding(.bottom, 15)
                .offset(x: -120)
            
            Text(document.title)
                .font(.system(size: 14, weight: .bold))
                .offset(x: 30)
                
        }
        .frame(width: 330, height: 80)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
    }
}

struct DocumentDetails : View{
    
    @State var document : Declaratie
    @State var showDocumentEdit = false
    
    var body : some View{
        ZStack{
            Text(document.title)
                .font(.system(size: 20, weight: .bold))
                .offset(y: -320)
            
            Text(document.category)
                .font(.system(size: 17, weight: .bold))
                .offset(y: -280)
                .multilineTextAlignment(.center)
                .padding(.leading, 20)
                .padding(.trailing, 20)
            
            HStack{
                document.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .frame(width: 230, height: 370)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
            //.offset(y: -30)
            
            HStack{
                Button(action: {showDocumentEdit.toggle()}){
                    HStack{
                        Image(systemName: "pencil.circle")
                            .foregroundColor(Color.white)
                            .font(.system(size: 20, weight: .bold))
                        
                        Text("Editare")
                            .foregroundColor(Color.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    .frame(width: 130, height: 60)
                    .background(RoundedRectangle(cornerRadius: 40).fill(Color.blue))
                }
                .sheet(isPresented: $showDocumentEdit){
                    PDFKitView(url: Bundle.main.url(forResource: document.pdfFile, withExtension: ".pdf")!)
                }
                
                
                Spacer()
                
                Button(action: {showDocumentEdit.toggle()}){
                    HStack {
                        Image(systemName: "eye.circle")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.white))
                }
                .sheet(isPresented: $showDocumentEdit){
                    PDFKitView(url: Bundle.main.url(forResource: document.pdfFile, withExtension: ".pdf")!)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .bold))
                }
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color.white))
            }
            .offset(y: 300)
            .padding(.leading, 50)
            .padding(.trailing, 50)
            
        }
        .frame(width: screen.width, height: screen.height)
        .background(Color(#colorLiteral(red: 0.9218111634, green: 0.9173565507, blue: 0.9369328618, alpha: 1)))
    }
}



struct Declaratie : Identifiable{
    var id = UUID()
    var title : String
    var category : String
    var image : Image
    var pdfFile : String
}

let documentData = [
    Declaratie(title: "Declarație pe proprie răspundere", category: "Indiferent de rata de incidență", image: Image("declaratie1"), pdfFile: "declaratie1"),
    Declaratie(title: "Adeverință de angajator", category: "Indiferent de rata de incidență", image: Image("declaratie2"), pdfFile: "declaratie2"),
    Declaratie(title: "Declarație pe proprie răspundere", category: "Rată de incidență mai mare de 4%, respectiv 7,5%", image: Image("declaratie3"), pdfFile: "declaratie3"),
    Declaratie(title: "Adeverință de angajator", category: "Rată de incidență mai mare de 4%, respectiv 7,5%", image: Image("declaratie4"), pdfFile: "declaratie4"),
    Declaratie(title: "Declarație pe proprie răspundere", category: "Tranzitarea unei localități carantinate", image: Image("declaratie5"), pdfFile: "declaratie5")
]
