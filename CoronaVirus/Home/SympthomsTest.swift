//
//  SympthomsTest.swift
//  CoronaVirus
//
//  Created by Milovan on 25.04.2021.
//

import SwiftUI
import Swift

struct SympthomsTest: View {
    
    var body: some View {
        VStack{
            Introducere()
        }
        .background(Color(#colorLiteral(red: 0.9646044374, green: 0.9647659659, blue: 0.9645816684, alpha: 1)))
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}

struct SympthomsTest_Previews: PreviewProvider {
    
    static var previews: some View {
        SympthomsTest()
    }
}

struct Introducere : View{
    
    @State var introducereDa = false
    @State var introducereNu = false
    
    var body: some View{
        if introducereDa == false{
            VStack{
                VStack{
                    GifView(imagine: "introducere_TE")
                        .frame(height: 200)
                        .offset(y: -150)
                    
                    Text("Triaj epidemiologic")
                        .foregroundColor(Color.black)
                        .font(.system(size: 25, weight: .bold))
                        .offset(y: -150)
                }
                .offset(y: 70)
                
                VStack(spacing: 20) {
                    Button(action: {introducereDa.toggle()}){
                        HStack{
                            Text("Incepe acum")
                                .foregroundColor(Color.black)
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(width: 250, height: 60)
                        .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                    }

                    Text("Vă rugăm să rețineți că datele și informațiile furnizate in acest formular nu sunt prelucrate de nimeni. \nAcest formular nu are nota medicala si este destinat doar pentru uz personal. Pentru mai multe informatii consultati medicul dumneavoastra de familie.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 12, weight: .regular))
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .offset(y: 140)
                }
            }
            .frame(width: screen.width, height: screen.height)
            }
        else
        {
            IntrebariFormular(question: intrebariFormular[0])
        }
    }
}

struct IntrebariFormular : View {
    
    @State var question : IntrebareFormular
    @State var nextQuestion = false
    @State var answer = true
    
    var body: some View{
        
        if nextQuestion == false {
            ZStack{
                GifView(imagine: question.imagine)
                    .frame(height: 200)
                    .offset(y: -150)
                
                VStack{
                    Text(question.title)
                        .font(.system(size: 15, weight: .bold))
                        .multilineTextAlignment(.center)
                        .offset(y: -130)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    
                    Text(question.intrebare)
                        .font(.system(size: 15, weight: .regular))
                        .multilineTextAlignment(.center)
                        .offset(y: -100)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                }
                .offset(y: 150)
                
                VStack(spacing: 20) {
                    Button(action: {self.answer = false; nextQuestion.toggle()}){
                        HStack{
                            Text("Da")
                                .foregroundColor(Color.black)
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(width: 250, height: 60)
                        .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                    }
                    
                    Button(action: {nextQuestion.toggle()}){
                        HStack{
                            Text("Nu")
                                .foregroundColor(Color.black)
                                .font(.system(size: 15, weight: .bold))
                        }
                        .frame(width: 250, height: 60)
                        .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                    }
                }
                .offset(y: question.intrebare == "" ? 200 : 250)
            }
            .frame(width: screen.width, height: screen.height)
        }
        else{
            if question.index == 5 {
                RezultatFormular(answer: self.answer)
            }
            else{
                nextView[question.index]
            }
        }
    }
}


struct RezultatFormular : View {
    
    @State var answer : Bool
    @State var preventie = false
    @State var redareTest = false
    @State var iesire = false
    
    var body: some View{
        
        if redareTest == false {
            if answer == true {
                if preventie == false {
                    VStack{
                        GifView_RepeatOnce(imagine: "success")
                            .frame(height: 200)
                            .offset(y: -50)
                        
                        Text("Totul pare in regula")
                            .font(.system(size: 25, weight: .bold))
                            .multilineTextAlignment(.center)
                            .offset(y: -50)
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                        
                        Text("Nu prezinti simptome asociate COVID-19")
                            .font(.system(size: 16, weight: .bold))
                            .offset(y: -30)
                        
                        Text("Nu uita sa te protejezi in continuare")
                            .font(.system(size: 16, weight: .bold))
                            .offset(y: 30)
                        
                        Button(action: {self.preventie.toggle()}) {
                            HStack{
                                Text("Afla mai multe detalii")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                            }
                        }
                        .offset(y: 40)
                        //.border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                        
                        VStack(spacing: 20) {
                            Button(action: {redareTest.toggle()}){
                                HStack{
                                    Text("Redare test")
                                        .foregroundColor(Color.black)
                                        .font(.system(size: 15, weight: .bold))
                                }
                                .frame(width: 250, height: 60)
                                .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                            }
                        }
                        .offset(y: 100)
                    }
                    .frame(width: screen.width, height: screen.height)
                }
                else{
                    PreventieView()
                }
            }
            else{
                VStack{
                    GifView_RepeatOnce(imagine: "atentie_Simptome")
                        .frame(height: 200)
                        .offset(y: -50)
                    
                    Text("Atentie!")
                        .font(.system(size: 25, weight: .bold))
                        .multilineTextAlignment(.center)
                        .offset(y: -50)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    
                    Text("Prezinti simptome asociate COVID-19")
                        .font(.system(size: 16, weight: .bold))
                        .offset(y: -30)
                    
                    Text("Nu este momentul sa te panichezi! \nIa legatura cu cadrele medicale si urmeaza indicatiile acestora.")
                        .font(.system(size: 16, weight: .bold))
                        .multilineTextAlignment(.center)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    
                    Text("Verifica simptomele asociate")
                        .font(.system(size: 16, weight: .bold))
                        .offset(y: 40)
                    
                    HStack{
                        Text("Afla mai multe detalii")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(#colorLiteral(red: 0.8940980434, green: 0.3246456385, blue: 0.3590234518, alpha: 1)))
                    }
                    .offset(y: 50)
                    
                    VStack(spacing: 20) {
                        Button(action: {redareTest.toggle()}){
                            HStack{
                                Text("Redare test")
                                    .foregroundColor(Color.black)
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .frame(width: 250, height: 60)
                            .background(RoundedRectangle(cornerRadius: 10) .fill(Color.white))
                        }
                    }
                    .offset(y: 100)
                }
                .frame(width: screen.width, height: screen.height)
            }
        }
        else{
            nextView[0]
        }
    }
}

struct IntrebareFormular : Identifiable{
    var id = UUID()
    var index : Int
    var title : String
    var intrebare : String
    var imagine : String
    var Raspuns : Bool
}

let nextView = [
    IntrebariFormular(question: intrebariFormular[0]), IntrebariFormular(question: intrebariFormular[1]),
    IntrebariFormular(question: intrebariFormular[2]), IntrebariFormular(question: intrebariFormular[3]),
    IntrebariFormular(question: intrebariFormular[4])
]

let intrebariFormular = [
    IntrebareFormular(index: 1, title: "Va aflati intr-una dintre situatiile de mai jos, cu debut brusc instalat?", intrebare: "Febra si tuse", imagine: "intrebare1", Raspuns: false),
    IntrebareFormular(index: 2, title: "Va aflati intr-una dintre situatiile de mai jos, cu debut brusc instalat?", intrebare: "Pierderea recenta a mirosului sau a gustului", imagine: "intrebare2", Raspuns: false),
    IntrebareFormular(index: 3, title: "Va aflati intr-una dintre situatiile de mai jos, cu debut brusc instalat?", intrebare: "Oricare trei sau mai multe simptome: \nfebra, tuse, slabiciune, durere de cap, dureri musculare, dureri in gat, \nobstructie nazala/rinoree, dificultati de respiratie, lipsa poftei de mancare, \ngreturi, varsaturi, diaree, status mental alterat (confuzie)", imagine: "febra_Simptome", Raspuns: false),
    IntrebareFormular(index: 4, title: "Ati intrat in contact in ultimele 14 zile cu persoane cu suspiciune sau diagnosticate cu infectie COVID-19?", intrebare: "", imagine: "intrebare3", Raspuns: false),
    IntrebareFormular(index: 5, title: "In prezent, aveti recomandata masura carantinei sau a izolarii?", intrebare: "", imagine: "intrebare4", Raspuns: false)
]
