//
//  ArticleView.swift
//  CoronaVirus
//
//  Created by Milovan on 05.03.2021.
//

import SwiftUI

let screen: CGRect = UIScreen.main.bounds

struct NewsView: View {
    @State var articles = articleData
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                ForEach(articles.indices, id: \.self) { index in
                    GeometryReader { geometry in
                        ArticleView(show: self.$articles[index].show, article: self.articles[index])
                            .offset(y: self.articles[index].show ? -geometry.frame(in: .global).minY : 0)
                    }
                    .frame(height: self.articles[index].show ? screen.height : 280)
                    .frame(maxWidth: self.articles[index].show ? .infinity : screen.width-60)
                }
            }
            .frame(width: screen.width)
            .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0))
        }
    }
}

struct NewsView_Previews: PreviewProvider {
    static var previews: some View {
        NewsView()
    }
}

/*func getImageColor() -> UIColor{
    var colors = UIImage(named: "preventie1").getColors()
    print(colors)
}*/

struct ArticleView: View {
    
    
    @Binding var show: Bool
    var article: Article
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 30.0) {
                Text("")
                    .font(.title).bold()
                Text("")
                    
            }
            .padding(30)
            .frame(maxWidth: show ? .infinity : screen.width-60, maxHeight: show ? .infinity : 280, alignment: .top)
            .offset(y: show ? 460 : 0)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y:20)
            .opacity(show ? 1 : 0)
            
            VStack {
                HStack(alignment: .top){
                    VStack(alignment: .leading, spacing: 8.0) {
                        Text(article.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            //.foregroundColor(article.color.UIColor().isDarkColor)
                        Text(article.description)
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    ZStack {
                        article.newsLogo
                            .resizable()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .aspectRatio(contentMode: .fit)
                            .opacity(show ? 0 : 1)
                            
                        
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
            .background(article.color.resizable().aspectRatio(contentMode: .fill))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            //.shadow(color: Color.red.opacity(2), radius: 20, x:0, y: 20)
            .onTapGesture {
                self.show.toggle()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.6))
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}

struct Article: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var image: Image
    var newsLogo: Image
    var color: Image
    var show: Bool
}

var articleData = [
    Article(title: "", description: "", image: Image("prevent1"), newsLogo: Image(""), color: Image("blackTest"), show: false),
    Article(title: "Arctile title 1", description: "Arcticle description 1", image: Image("prevent1"), newsLogo: Image(systemName: "newspaper"), color: Image("blackTest"), show: false),
    Article(title: "Arctile title 1", description: "Arcticle description 1", image: Image("prevent2"), newsLogo: Image(systemName: "newspaper"), color: Image("prevent2"), show: false)
]
