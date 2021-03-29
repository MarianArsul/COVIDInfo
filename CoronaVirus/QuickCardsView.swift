//
//  QuickCardsView.swift
//  CoronaVirus
//
//  Created by Milovan on 28.03.2021.
//




import SwiftUI

struct QuickCardsView: View {
    var section: Section
    var width: CGFloat = 200
    var height: CGFloat = 200
    var QuickCardsViewIndex = 0
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Text(section.title)
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 1000, alignment: .center)
                    .foregroundColor(.black)
                Spacer()
            }
            
            Text(section.description)
                .font(.system(size:15))
                .frame(maxWidth: 240 , alignment: .center)
            
            
            section.image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 275)
                .padding(.bottom,-33)
    
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
        .frame(width: width, height: height)
        .background(section.color)
        .cornerRadius(30)
        .shadow(color: section.color.opacity(1), radius: 20, x: 10, y: 20)
}

struct QuickCardsView_Previews: PreviewProvider {
    static var previews: some View {
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(sectionData) { item in
                    QuickCardsView(section: item)
                }
            }
            .padding(30)
            .padding(.bottom, 20)
            .padding(.top, -15)
            
            }
        }
    }
}

struct Section: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var description_height: CGFloat
    var image: Image
    var color: Color
}

let sectionData = [
    Section(title: "Prevenție", description: "Cum să te protejezi", description_height: 50, image: Image("prevent1"), color: Color(#colorLiteral(red: 0.9725490196, green: 0.9333333333, blue: 0.9176470588, alpha: 1))),
    Section(title: "Myth-busters", description: "Nu mai crede tot ce auzi!", description_height: 30, image: Image("myth-busters"), color: Color(#colorLiteral(red: 0.9177460074, green: 0.7902315855, blue: 0.9823716283, alpha: 1))),
    Section(title: "Documente utile", description: "Poate o să îți vină de folos", description_height: 30, image: Image("documente-utile"), color: Color(#colorLiteral(red: 0.918138504, green: 0.9530698657, blue: 0.9800389409, alpha: 1))),
    Section(title: "Surse sigure", description: "De unde să te informezi", description_height: 30, image: Image("trusted-sources"), color: Color(#colorLiteral(red: 0.9710895419, green: 0.8475009799, blue: 0.7614192367, alpha: 1)))
]

struct FullCardsView: View {
    
    @Binding var show: Bool
    
    var body: some View{
        ZStack(alignment: .top){
            VStack(alignment: .leading, spacing: 30.0) {
                Text("Card title")
                Text("Card description")
                    .font(.title).bold()
            }
            .padding(30)
            .frame(maxWidth: show ? .infinity : screen.width-60, maxHeight: show ? .infinity : 280, alignment: .top)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y:20)
            .opacity(show ? 1 : 0)
            
            VStack{
                HStack(alignment: .top){
                    VStack(alignment: .leading, spacing: 8.0){
                        Text("Content")
                            .font(.system(size: 24, weight: .bold))
                        Text("Content")
                }
                    
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
                
            Spacer()
            Image("prevent1").resizable()
                //.frame(width: screen.width-60, height: 280)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height:140, alignment: .top)
        }
            .padding(show ? 30:20)
            .padding(.top, show ? 30:0)
            .frame(maxWidth: show ? .infinity : screen.width - 60, maxHeight: show ? 460 : 280)
            .background(Color(#colorLiteral(red: 0.9725490196, green: 0.9333333333, blue: 0.9176470588, alpha: 1)))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: Color(#colorLiteral(red: 0.9725490196, green: 0.9333333333, blue: 0.9176470588, alpha: 1)).opacity(0.3), radius: 20, x:0, y: 20)
            .onTapGesture {
                self.show.toggle()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.6))
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}
