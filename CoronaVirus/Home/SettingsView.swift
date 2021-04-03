//
//  SettingsView.swift
//  CoronaVirus
//
//  Created by Milovan on 27.03.2021.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Text("Setări")
                    .font(.system(size: 28, weight: .bold))
                    .offset(y: -20)
                MenuRow(menuOption: "Nume",menuIcon: "person.crop.circle")
                MenuRow(menuOption: "Locație", menuIcon: "location.viewfinder")
                MenuRow(menuOption: "Despre", menuIcon: "info.circle")
            }
            .frame(maxWidth: .infinity)
            .frame(height:300)
            .background(LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)), Color(#colorLiteral(red: 0.8705882353, green: 0.8941176471, blue: 0.9450980392, alpha: 1))]), startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 20)
            .padding(.horizontal, 30)
            .overlay(
                Image(systemName: "gear")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                    .offset(y: -150)
            )
        }
        .padding(.bottom, 30)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

struct MenuRow: View {
    var menuOption: String
    var menuIcon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: menuIcon)
                .font(.system(size: 20, weight: .bold))
                .imageScale(.large)
                .frame(width: 32, height: 32)
            Text(menuOption)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(width: 120, alignment: .leading)
            Image(systemName: "chevron.right")
        }
        
    }
}
