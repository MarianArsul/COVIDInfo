//
//  QuickCardsView.swift
//  CoronaVirus
//
//  Created by Milovan on 28.03.2021.
//
import SwiftUI
struct CardsView: View {
    
    var card : Card
    
    var body: some View {
        
        ZStack(alignment: .bottom){
            ZStack {
                card.image
                    .resizable()
                    .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fill/*@END_MENU_TOKEN@*/)
                    //.accessibility(hidden: true)
            }
            .frame(width: 250, height: 330)
            .background(RoundedRectangle(cornerRadius: 10) .fill(Color(#colorLiteral(red: 0.9414022679, green: 0.9414022679, blue: 0.9414022679, alpha: 1))))
            
            HStack {
                VStack(alignment: .leading) {
                    Text(card.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(#colorLiteral(red: 0.1024787799, green: 0.1775858402, blue: 0.2037084699, alpha: 1)))
                }
                Spacer()
            }
            .padding()
            .frame(width: 250)
            .accessibilityElement(children: .combine)
            .background(VisualEffectBlur())
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        //.shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
        .padding()
        .accessibilityElement(children: .contain)
    }
}

struct CardsView_Previews: PreviewProvider {
    static var previews: some View {
        CardsView(card: cardsData[0])
    }
}

struct Card: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var description_height: CGFloat
    var image: Image
    var color: Color
}

let cardsData = [
    Card(title: "Prevenție", description: "", description_height: 50, image: Image("handwashing_U"), color: Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))),
    Card(title: "Simptome", description: "", description_height: 30, image: Image("cold_U"), color: Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))),
    Card(title: "Intrebări frecvente", description: "", description_height: 30, image: Image("question_U"), color: Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))),
    Card(title: "Documente", description: "", description_height: 30, image: Image("document_U"), color: Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
]

