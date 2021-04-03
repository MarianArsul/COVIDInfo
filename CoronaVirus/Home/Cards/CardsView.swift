//
//  QuickCardsView.swift
//  CoronaVirus
//
//  Created by Milovan on 28.03.2021.
//




import SwiftUI

struct CardsView: View {
    var card: Card
    var width: CGFloat = 200
    var height: CGFloat = 200
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text(card.title)
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 1000, alignment: .center)
                    .foregroundColor(.black)
                Spacer()
            }
            
            Text(card.description)
                .font(.system(size:15))
                .frame(maxWidth: 240 , alignment: .center)
            
            
            card.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 275)
                .padding(.bottom,-33)
    
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .frame(width: width, height: height)
        .background(card.color)
        .cornerRadius(30)
        .shadow(color: card.color.opacity(1), radius: 20, x: 10, y: 20)
}

struct CardsView_Previews: PreviewProvider {
    static var previews: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(cardsData) { item in
                    CardsView(card: item)
                }
            }
            .padding(30)
            .padding(.bottom, 20)
            .padding(.top, -15)
            
            }
        }
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
    Card(title: "Prevenție", description: "Cum să te protejezi", description_height: 50, image: Image("prevent1"), color: Color(#colorLiteral(red: 0.9725490196, green: 0.9333333333, blue: 0.9176470588, alpha: 1))),
    Card(title: "Simptome", description: "Covid-19", description_height: 30, image: Image("simptome2"), color: Color(#colorLiteral(red: 0.8667405248, green: 0.9350652099, blue: 0.9954409003, alpha: 1))),
    Card(title: "Myth-busters", description: "Nu mai crede tot ce auzi!", description_height: 30, image: Image("myth-busters"), color: Color(#colorLiteral(red: 0.9177460074, green: 0.7902315855, blue: 0.9823716283, alpha: 1))),
    Card(title: "Documente utile", description: "Poate o să îți vină de folos", description_height: 30, image: Image("documente-utile"), color: Color(#colorLiteral(red: 0.918138504, green: 0.9530698657, blue: 0.9800389409, alpha: 1))),
    Card(title: "Surse sigure", description: "De unde să te informezi", description_height: 30, image: Image("trusted-sources"), color: Color(#colorLiteral(red: 0.9710895419, green: 0.8475009799, blue: 0.7614192367, alpha: 1)))
]

