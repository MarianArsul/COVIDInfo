//
//  HomeView.swift
//  CoronaVirus
//
//  Created by Milovan on 05.03.2021.
//

import SwiftUI

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
    
    @State var showSettings = false
    let screen: CGRect = UIScreen.main.bounds
    
    var body: some View{
        ScrollView {
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
                    .sheet(isPresented: $showSettings) {
                        ContentView()
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
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        ForEach(sectionData) { item in
                            SectionView(section: item)
                            /*GeometryReader { geometry in
                                SectionView(section: item)
                                    .rotation3DEffect(Angle(degrees: Double(geometry.frame(in: .global).minX - 30) / -20), axis: (x: 0, y: 10.0, z: 0))
                            }
                            .frame(width: 275, height: 275)*/
                        }
                    }
                    .padding(30)
                    .padding(.bottom, 30)
                    .padding(.top, -15)
                    
                }
                
                
                HStack {
                    Text("Știri")
                        .font(.title).bold()
                }
                .padding(.leading,-160)
                .offset(y: -40)
                
                NewsView()
                    .offset(y: -30)
                
                Spacer()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View{
        HomeView()
    }
}

struct SectionView: View {
    
    var section: Section
    var width: CGFloat = 200
    var height: CGFloat = 200
    
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
    Section(title: "Prevenție", description: "Cum să te protejezi", description_height: 50, image: Image("prevent1"), color: Color(#colorLiteral(red: 0.9708561301, green: 0.9352309108, blue: 0.9176588655, alpha: 1))),
    Section(title: "Myth-busters", description: "Nu mai crede tot ce auzi!", description_height: 30, image: Image("myth-busters"), color: Color(#colorLiteral(red: 0.9177460074, green: 0.7902315855, blue: 0.9823716283, alpha: 1))),
    Section(title: "Documente utile", description: "Poate o să îți vină de folos", description_height: 30, image: Image("documente-utile"), color: Color(#colorLiteral(red: 0.918138504, green: 0.9530698657, blue: 0.9800389409, alpha: 1))),
    Section(title: "Surse sigure", description: "De unde să te informezi", description_height: 30, image: Image("trusted-sources"), color: Color(#colorLiteral(red: 0.9710895419, green: 0.8475009799, blue: 0.7614192367, alpha: 1)))
]
