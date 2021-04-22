//
//  HomeView.swift
//  CoronaVirus
//
//  Created by Milovan on 05.03.2021.
//

/*import SwiftUI


//function used to display message based on time of day
func timeOfDay() -> String {
    let hour = Calendar.current.component(.hour, from: Date()) // get current hour
    var messageToBeDisplayed = ""
    //depending on var hour, switch to the appropiate greeting
    switch hour {
        case 6..<12 : messageToBeDisplayed = "Bună dimineața, "
        case 12..<17 : messageToBeDisplayed = "Bună ziua, "
        default: messageToBeDisplayed = "Bună seara, "
        }
    return messageToBeDisplayed
}

struct HomeView: View {
    
    @State var articles = articleData
    @State var cards = cardsData
    @State var viewState = CGSize.zero
    let screen: CGRect = UIScreen.main.bounds
    
    @State public var NewsViewFullScreen = false
    @State public var showSettings = false
    @State public var showPreventie = false
    @State public var showSimptome = false
    @State public var showMythBusters = false
    @State public var showDocumenteUtile = false
    @State public var showSurseSigure = false
    
    var body: some View{
        ScrollView {
            ZStack {
                Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
                    .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                VStack {
                    HStack {
                        Text (timeOfDay()+" Milovan")
                            .font(.system(size: 28, weight: .bold))
                        Spacer()
                        
                        Button(action: {self.showSettings.toggle()}) {
                            Image(systemName: "gear")
                                .renderingMode(.original)
                                .font(.system(size: 24, weight: .medium))
                                .frame(width: 36, height: 36)
                                .background(Color.white)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 1, x: /*@START_MENU_TOKEN@*/0.0/*@END_MENU_TOKEN@*/, y: 1)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 10)
                        }
                        
                    }
                    .padding(.horizontal)
                    .padding(.leading, 14)
                    .padding(.top,20)
                    
                    HStack {
                        Text("Iată ultimele știri")
                            .font(.system(size:20))
                            .multilineTextAlignment(.leading)
                            .font(.subheadline)
                            .padding(.horizontal,30)
                            .foregroundColor(.gray)
                            .padding(.top, -1)
                        Spacer()
                    }
                    
                    ScrollView(.horizontal){
                        HStack(spacing: 30){
                            Button(action: {self.showPreventie.toggle()}) {
                                //CardsView(card: cards[0])}
                                .sheet(isPresented: $showPreventie) {
                                    PreventieView()}
                            Button(action: {self.showSimptome.toggle()}) {
                                CardsView(card: cards[1])}
                                .sheet(isPresented: $showSimptome) {
                                    SimptomeView()}
                            Button(action: {self.showMythBusters.toggle()}) {
                                CardsView(card: cards[2])}
                                .sheet(isPresented: $showMythBusters) {
                                    MythBustersView()}
                            Button(action: {self.showDocumenteUtile.toggle()}) {
                                CardsView(card: cards[3])}
                                .sheet(isPresented: $showDocumenteUtile) {
                                    DocumentsView()}
                            
                        }
                        .offset(x: 90)
                        .frame(width: 1000, height: 310)
                    }
                    //.padding(.bottom, 40)
                    .padding(.top, -50)
                    
                    HStack {
                        Text("Știri")
                            .font(.title).bold()
                    }
                    .padding(.leading,-160)
                    .offset(y: -40)
                    .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
                    
                    VStack(spacing: 20){
                        ForEach(articles.indices, id: \.self) { index in
                            GeometryReader { geometry in
                                ArticleView(show: self.$articles[index].show, article: self.articles[index])
                                    .offset(y: self.articles[index].show ? -geometry.frame(in: .global).minY : 0)
                            }
                            .frame(height: self.articles[index].show ? screen.height : 280)
                            .frame(maxWidth: self.articles[index].show ? .infinity : screen.width-60)
                        
                    }
                        
                }
                .offset(y: -30)
                
                Spacer()
                    
            }
        }
            
    }
        .padding(.top, 44)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .offset(y: showSettings ? -400:0)
        .offset(y: viewState.height)
        .rotation3DEffect(Angle(degrees: showSettings ? Double(viewState.height / 10) - 10 : 0), axis: (x: 10, y: 0, z: 0.0))
        .shadow(color: showSettings ? Color.black.opacity(4) : Color.white, radius: showSettings ? 20 : 0, x:0, y:20)
        .scaleEffect(showSettings ? 0.9:1)
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0))
        .edgesIgnoringSafeArea(.all)
        
        
        if showSettings == true {
            SettingsView()
                .background(Color.black.opacity(0.001))
                .offset(y: showSettings ? 0:100)
                .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0))
                .onTapGesture {
                    self.showSettings.toggle()
                }
                .gesture(
                    DragGesture().onChanged {value in self.viewState = value.translation}
                    .onEnded{value in
                        if self.viewState.height > 50 {
                            self.showSettings = false
                        }
                        self.viewState = .zero
                    }
            )
        }
        
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View{
        HomeView()
    }
}

}
*/
