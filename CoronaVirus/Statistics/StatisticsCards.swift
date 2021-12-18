//
//  StatisticsTest.swift
//  CoronaVirus
//
//  Created by Milovan on 15.05.2021.
//

import SwiftUI

struct QuickStatCards: View {
    
    @State var link: String
    @State var title: String
    @State var actualizare: String
    
    var body: some View {
        ZStack{
            VStack(){
                HStack {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .offset(y: 5)
                        .offset(x: -20)
                    
                    Spacer()
                }
                .padding(.leading, 50)
                
            }
            .frame(width: 250, height: 80)
            .background(Color.white)
            .offset(y: -80)
            
            .zIndex(2)
            
            ZStack {
                Webview(url: URL(string: link)!)
                    .offset(y: 0)
            }
            .frame(width: 260, height: 280)
            
        }
        .frame(width: 220, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
    }
    
    /*
     
     */
}

struct StatisticsCards_Previews: PreviewProvider {
    static var previews: some View {
        QuickStatCards(link: "https://datelazi.ro/embed/confirmed_cases", title: "Cazuri confimate", actualizare: "15 mai 2021")
    }
}

struct extendedStats: View{
    
    @State var link: String
    @State var title: String
    @State var actualizare: String
    @State var cardHeight: CGFloat
    
    var body: some View{
        ZStack{
            VStack{
                HStack {
                    Text(title)
                        .foregroundColor(Color.black)
                        .font(.system(size: 25, weight: .bold))
                    
                    Spacer()
                }
                .padding(.leading, 20)
                .offset(y: 10)
                
                HStack {
                    Text("Ultima actualizare: \(actualizare)")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color.black)
                    
                    Spacer()
                }
                .padding(.leading, 20)
                .offset(y: 10)
            }
            .frame(width: 360, height: 100)
            .background(VisualEffectBlur())
            .clipShape(RoundedCorners(tl: 20, tr: 20, bl: 0, br: 0))
            .offset(y: -310)
            .zIndex(2)
            
            
            Webview(url: URL(string: link)!)
                .frame(width: 370, height: cardHeight)
        }
        .frame(width: 360, height: cardHeight-10)
        .background(VisualEffectBlur())
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
        .padding(.bottom, 20)
    }
}

struct RoundedCorners: Shape {
    var tl: CGFloat = 0.0
    var tr: CGFloat = 0.0
    var bl: CGFloat = 0.0
    var br: CGFloat = 0.0

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.size.width
        let h = rect.size.height

        // Make sure we do not exceed the size of the rectangle
        let tr = min(min(self.tr, h/2), w/2)
        let tl = min(min(self.tl, h/2), w/2)
        let bl = min(min(self.bl, h/2), w/2)
        let br = min(min(self.br, h/2), w/2)

        path.move(to: CGPoint(x: w / 2.0, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr,
                    startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)

        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br,
                    startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)

        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl,
                    startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)

        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(center: CGPoint(x: tl, y: tl), radius: tl,
                    startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)

        return path
    }
}
