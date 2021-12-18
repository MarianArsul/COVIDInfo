//
//  VaccineQuestions.swift
//  CoronaVirus
//
//  Created by Milovan on 15.05.2021.
//

import SwiftUI
import SwiftSoup
import PartialSheet

struct vaccineQuestion : Identifiable{
    var id = UUID()
    var question: String
    var answer: String
}

var vaccineQuestions = [vaccineQuestion]()

func vaccineQuestionsScrape() {
    do{
        let urlArticol = URL(string: "https://vaccinare-covid.gov.ro/resurse/intrebari-si-raspunsuri/")!
        let html = try String(contentsOf: urlArticol)

        let document : Elements = try SwiftSoup.parse(html).select("main")
        let div : Elements = try document.select("div.entry-content-text")
        let ps : Elements = try div.select("p")


        var index = 0
        var question: vaccineQuestion = vaccineQuestion(question: "", answer: "")

        for entry: Element in div.array(){
            
            if index == 0{
                question.question = try entry.text()
                index += 1
            }
            
            if index == 1 {
                question.answer = try entry.text()
                index += 1
            }
            
            if index == 2 {
                vaccineQuestions.append(question)
                index = 0
                question = vaccineQuestion(question: "", answer: "")
            }
        }
    }catch Exception.Error(let type, let message) {
        print(message, type)
    } catch {
        print("error")
    }
}


struct VaccineQuestions: View {
    
    @EnvironmentObject var partialSheetManager : PartialSheetManager
    
    var body: some View {
        NavigationView(){
            ScrollView(.vertical, showsIndicators: false){
                VStack(spacing: 20){
                    ForEach(vaccineQuestions){ item in
                        Button(action: {self.partialSheetManager.showPartialSheet({}){answerSheet(intrebare: item.question, raspuns: item.answer)}}, label:{questionCard(intrebare: item)}
                        )
                    }
                }
                .offset(y: 200)
            }
            .frame(width: screen.width, height: screen.height)
            .navigationBarTitle("Intrebari frecvente")
        }
    }
}

struct VaccineQuestions_Previews: PreviewProvider {
    static var previews: some View {
        VaccineQuestions()
            .addPartialSheet()
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(PartialSheetManager())
    }
}

struct questionCard: View{
    
    @State var intrebare: vaccineQuestion
    
    var body: some View{
        
        HStack(spacing: 10){
            Text(intrebare.question)
                .foregroundColor(Color.black)
                .font(.system(size: 20, weight: .bold))
                .padding(.leading, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .foregroundColor(Color.black)
                .font(.system(size: 20, weight: .bold))
                .padding(.trailing, 20)
       }
       .frame(width: 350)
       .background(VisualEffectBlur())
       .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

struct answerSheet : View{
    
    @State var intrebare: String
    @State var raspuns: String
    
    var body: some View{
        VStack {
            Group {
                Text(intrebare)
                    .font(.headline)
                    .padding(.top, 30)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)

            }
            .padding()
            .frame(height: 50)
            
            VStack {
                Text(raspuns)
                    .padding(.leading, 20)
                    .padding(.trailing, 20)
                    .padding(.top, 40)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

