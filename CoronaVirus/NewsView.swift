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

struct ArticleView: View {
    
    @Binding var show: Bool
    var article: Article
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 30.0) {
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. In vel enim sed arcu auctor venenatis ut id nisl. Nullam suscipit felis ut sapien viverra suscipit. Pellentesque volutpat fringilla porta. Nullam ac vulputate lectus. Ut non vestibulum odio, vel varius tortor. Vivamus et velit finibus, gravida tortor at, feugiat est. Nunc ac mi nec nulla venenatis semper. Mauris ipsum libero, tincidunt eleifend venenatis id, molestie in nisi. Quisque id dolor vel urna egestas pretium. Phasellus ac leo vitae mi cursus molestie. Nulla eget tellus dapibus libero tempus lacinia ut et urna. Morbi nec nisl quis ipsum aliquam dapibus id eleifend felis. Mauris egestas consequat commodo.")
                Text("About this story")
                    .font(.title).bold()
                Text("Praesent et elit massa. Aliquam erat volutpat. Morbi mauris massa, pellentesque eu aliquam in, consequat sed nunc. Curabitur mattis sapien convallis urna dictum, eu ultricies libero placerat. Etiam euismod sem ante, ac fringilla purus tincidunt vel. Donec pretium arcu a sapien posuere imperdiet. Mauris vel nunc fringilla, pretium arcu sed, pharetra quam. Suspendisse id viverra magna.")
                Text("Sed lobortis, elit ac tincidunt fermentum, tortor risus dapibus lorem, sit amet aliquam tellus nulla sit amet risus. Vivamus aliquam tristique vulputate. Phasellus dictum laoreet ante vitae iaculis. Duis consectetur blandit egestas. Nullam sodales malesuada libero, et condimentum leo convallis ut. Aenean convallis bibendum ante, in iaculis ipsum consectetur ac. Duis lectus justo, rutrum non libero a, posuere lacinia tellus. Aliquam auctor, orci nec maximus ultricies, velit nulla tempor est, nec scelerisque ligula dui at elit. Aliquam ac vulputate quam. In accumsan libero non erat molestie, quis egestas est feugiat.")
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
                        Text(article.description)
                    }
                    Spacer()
                    
                    ZStack {
                        article.newsLogo
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
                Spacer()
                article.image.resizable()
                    //.frame(width: screen.width-60, height: 280)
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(height:140, alignment: .top)
            }
            .padding(show ? 30:20)
            .padding(.top, show ? 30:0)
            .frame(maxWidth: show ? .infinity : screen.width - 60, maxHeight: show ? 460 : 280)
            .background(article.color)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: article.color.opacity(0.3), radius: 20, x:0, y: 20)
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
    var color: Color
    var show: Bool
}

var articleData = [
    Article(title: "Arctile title 1", description: "Arcticle description 1", image: Image("prevent1"), newsLogo: Image(systemName: "newspaper"), color: Color(#colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)), show: false),
    Article(title: "Arctile title 1", description: "Arcticle description 1", image: Image("prevent1"), newsLogo: Image(systemName: "newspaper"), color: Color(#colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)), show: false),
    Article(title: "Arctile title 1", description: "Arcticle description 1", image: Image("prevent1"), newsLogo: Image(systemName: "newspaper"), color: Color(#colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)), show: false)
]
