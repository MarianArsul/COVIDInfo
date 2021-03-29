//
//  CardsView.swift
//  CoronaVirus
//
//  Created by Milovan on 29.03.2021.
//

import SwiftUI


struct CardsView: View {
    @State var cards = cardsData
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(cards.indices, id: \.self) { index in
                    GeometryReader { geometry in
                        CardView(show: self.$cards[index].show, card: self.cards[index])
                            .offset(y: self.cards[index].show ? -geometry.frame(in: .global).minY : 0)
                    }
                    .frame(height: self.cards[index].show ? screen.height : 200)
                    .frame(maxWidth: self.cards[index].show ? .infinity : 200)
                }
            }
            .frame(width: 950, height: 25000)
            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0))
        }
    }
}

struct CardsView_Previews: PreviewProvider {
    static var previews: some View {
        CardsView()
    }
}

/*func getImageColor() -> UIColor{
    var colors = UIImage(named: "preventie1").getColors()
    print(colors)
}*/

struct CardView: View {

    @Binding var show: Bool
    var card: Card
    var width: CGFloat = 200
    var height: CGFloat = 200
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                HStack(spacing: -50) {
                    Text(card.title)
                        .font(.system(size: 20, weight: .bold))
                        .frame(width: 240, alignment: .top)
                        .foregroundColor(.black)
                }
                
                Text(card.description)
                    .font(.system(size:15))
                    .frame(maxWidth: 240 , alignment: .center)
                
                
                card.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200)
                    .padding(.bottom,-30)
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)
            .frame(width: width, height: height)
            .background(card.color)
            .cornerRadius(30)
            .shadow(color: card.color.opacity(1), radius: 20, x: 10, y: 20)
            
            VStack {
                HStack(alignment: .top){
                    VStack(alignment: .leading, spacing: 8.0) {
                        if show == true{
                            Text(card.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                //.foregroundColor(article.color.UIColor().isDarkColor)
                            Text(card.description)
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                    
                    ZStack {
                        VStack {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width:  36, height: 36)
                        .background(Color.black)
                        .clipShape(Circle())
                        .opacity(show  ? 1: 0)
                    }
                }
            }
            .padding(show ? 30:20)
            .padding(.top, show ? 30:0)
            .frame(maxWidth: show ? .infinity : screen.width - 60, maxHeight: show ? 460 : 280)
            .background(show ? card.color: Color.white.opacity(-30))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: Color.red.opacity(2), radius: 20, x:0, y: 20)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.6))
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        .onTapGesture {
            self.show.toggle()
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
    var show: Bool
}

let cardsData = [
    Card(title: "Prevenție", description: "Cum să te protejezi", description_height: 50, image: Image("prevent1"), color: Color(#colorLiteral(red: 0.9725490196, green: 0.9333333333, blue: 0.9176470588, alpha: 1)), show: false),
    Card(title: "Myth-busters", description: "Nu mai crede tot ce auzi!", description_height: 30, image: Image("myth-busters"), color: Color(#colorLiteral(red: 0.9177460074, green: 0.7902315855, blue: 0.9823716283, alpha: 1)), show: false),
    Card(title: "Documente utile", description: "Poate o să îți vină de folos", description_height: 30, image: Image("documente-utile"), color: Color(#colorLiteral(red: 0.918138504, green: 0.9530698657, blue: 0.9800389409, alpha: 1)), show: false),
    Card(title: "Surse sigure", description: "De unde să te informezi", description_height: 30, image: Image("trusted-sources"), color: Color(#colorLiteral(red: 0.9710895419, green: 0.8475009799, blue: 0.7614192367, alpha: 1)), show: false)
]
