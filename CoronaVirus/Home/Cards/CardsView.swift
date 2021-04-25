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
        ZStack{
            card.image
                .resizable()
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 350)
                .offset(y: 10)
            
            VStack(alignment: .trailing) {
                Text(card.title)
                    .foregroundColor(Color.white)
                    .font(.system(size: 25, weight: .bold))
                    .shadow(radius: 20)
                    //.zIndex(2)
            }
            .frame(width: 250,height: 70)
            .background(RoundedRectangle(cornerRadius: 10).fill(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)), Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.4281312046))]), startPoint: .top, endPoint: .bottom)))
            .offset(y: 140)
            .shadow(radius: 100)
            .zIndex(2)
        }
        .frame(width: 250, height: 350)
        .background(RoundedRectangle(cornerRadius: 20).fill(card.color))
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
    Card(title: "Prevenție", description: "", description_height: 50, image: Image("preventie"), color: Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))),
    Card(title: "Simptome", description: "", description_height: 30, image: Image("simptome"), color: Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))),
    Card(title: "Intrebări frecvente", description: "", description_height: 30, image: Image("intrebariFrecventeCard"), color: Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))),
    Card(title: "Documente", description: "", description_height: 30, image: Image("documente"), color: Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)))
]

