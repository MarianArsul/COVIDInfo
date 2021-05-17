//
//  MythBustersView.swift
//  CoronaVirus
//
//  Created by Milovan on 05.03.2021.
//

//Main colour: 407BFF

import SwiftUI
import PartialSheet

struct VaccinationView: View {
    
    @EnvironmentObject var partialSheetManager : PartialSheetManager
    
    @State var showIntroVaccinare = false
    @State var showResurseInfoSigure = false
    @State var showResurseInfoInselatoare = false
    @State var showResurseDict = false
    
    var body: some View {
        NavigationView(){
            ScrollView(.vertical, showsIndicators: false){
                NavigationLink(destination: Webview(url: URL(string: "https://vaccinare-covid.gov.ro/resurse/intrebari-si-raspunsuri/")!).frame(height: screen.height + 800)) {
                    ZStack{
                         Image("vaccinare_U")
                             .resizable()
                             .aspectRatio(contentMode: .fit)
                             .offset(x: 90)
                             .frame(width:170, height: 170)
                         
                         Text("De ce")
                             .foregroundColor(Color.black)
                             .font(.system(size: 20, weight: .bold))
                             .offset(x: -128)
                             .offset(y: -40)
                         
                         Text("sa ma")
                             .foregroundColor(Color.black)
                             .font(.system(size: 25, weight: .bold))
                             .offset(x: -120)
                             .offset(y: -15)
                         
                         Text("vaccinez ?")
                             .foregroundColor(Color.black)
                             .font(.system(size: 30, weight: .bold))
                             .offset(x: -80)
                             .offset(y: 14)
                         
                         HStack{
                             Text("Vezi raspunsul")
                                 .foregroundColor(Color(#colorLiteral(red: 0.2509803922, green: 0.4823529412, blue: 1, alpha: 1)))
                                 .font(.system(size: 15, weight: .bold))
                             
                             Image(systemName: "arrow.right")
                                 .foregroundColor(Color(#colorLiteral(red: 0.2509803922, green: 0.4823529412, blue: 1, alpha: 1)))
                                 .font(.system(size: 15, weight: .bold))
                         }
                         .offset(x: -85)
                         .offset(y: 50)
                         
                     }
                     .frame(width: 340, height: 200)
                     .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                     .padding(.leading, 20)
                     .padding(.top, 10)
                     .padding(.bottom, 10)
                     .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                     .offset(x: -13)
                     .onAppear(perform: {
                        vaccineQuestionsScrape()
                     })
                }
                 
                 //.shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                 //.offset(x: -13)
                
                VStack{
                    Text("STATISTICI VACCINARE")
                        .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                        .font(.system(size: 15, weight: .bold))
                        .offset(x: -90)
                    
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack(spacing: 10){
                            QuickStatCards(link: "https://datelazi.ro/embed/total_vaccine", title: "Doze administrate", actualizare: "15 mai 2021")
                            
                            QuickStatCards(link: "https://datelazi.ro/embed/vaccine_immunization", title: "Persoane imunizate", actualizare: "15 mai 2021")
                        }
                        .offset(x: 16)
                        .frame(height: 340)
                    }
                    .offset(y: -30)
                }
                
                VStack{
                    Text("RESURSE UTILE")
                        .foregroundColor(Color(#colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)))
                        .font(.system(size: 15, weight: .bold))
                        .offset(x: -120)
                        .offset(y: -40)
                    
                    ScrollView(.horizontal, showsIndicators: false){
                        HStack(spacing: 10){
                            Button(action: {showResurseInfoSigure.toggle()}) {
                                VStack{
                                    Image(resurseUtileArray[0].image)
                                        .resizable().frame(width: 250, height: 250)
                                        .offset(y: -20)
                                    
                                    Text(resurseUtileArray[0].titlu)
                                        .foregroundColor(Color.black)
                                        .font(.system(size: 20, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .padding(.leading, 20)
                                        .padding(.trailing, 20)
                                }
                                .frame(width: 300, height: 400)
                                .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                            }
                            .sheet(isPresented: $showResurseInfoSigure){
                                Webview(url: URL(string: resurseUtileArray[0].link)!)
                                    .frame(height: screen.height + 200)
                                    //.offset(y: -150)
                            }
                            
                            Button(action: {showResurseInfoInselatoare.toggle()}) {
                                VStack{
                                    Image(resurseUtileArray[1].image)
                                        .resizable().frame(width: 250, height: 250)
                                        .offset(y: -20)
                                    
                                    Text(resurseUtileArray[1].titlu)
                                        .foregroundColor(Color.black)
                                        .font(.system(size: 20, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .padding(.leading, 20)
                                        .padding(.trailing, 20)
                                }
                                .frame(width: 300, height: 400)
                                .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                            }
                            .sheet(isPresented: $showResurseInfoInselatoare){
                                Webview(url: URL(string: resurseUtileArray[1].link)!)
                                    .frame(height: screen.height + 200)
                                    //.offset(y: -150)
                            }
                            
                            Button(action: {showResurseDict.toggle()}) {
                                VStack{
                                    Image(resurseUtileArray[2].image)
                                        .resizable().frame(width: 250, height: 250)
                                        .offset(y: -20)
                                    
                                    Text(resurseUtileArray[2].titlu)
                                        .foregroundColor(Color.black)
                                        .font(.system(size: 20, weight: .bold))
                                        .multilineTextAlignment(.center)
                                        .padding(.leading, 20)
                                        .padding(.trailing, 20)
                                }
                                .frame(width: 300, height: 400)
                                .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                                .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                            }
                            .sheet(isPresented: $showResurseDict){
                                Webview(url: URL(string: resurseUtileArray[2].link)!)
                                    .frame(height: screen.height + 200)
                                    //.offset(y: -150)
                            }
                        }
                        .frame(height: 430)
                        .padding(.leading, 20)
                    }
                    .offset(y: -40)
                    
                    Button(action: {}) {
                        HStack{
                            Text("Etapele crearii unui vaccin")
                                .foregroundColor(Color.black)
                                .padding(.leading, 20)
                                .font(.system(size: 20, weight: .bold))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(Color.black)
                                .font(.system(size: 20, weight: .bold))
                                .padding(.trailing, 20)
                        }
                        .frame(width: 350, height: 70)
                        .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                        .offset(y: -40)
                    }
                    
                    HStack{
                        Text("Etapele de vaccinare")
                            .foregroundColor(Color.black)
                            .padding(.leading, 20)
                            .font(.system(size: 20, weight: .bold))
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .foregroundColor(Color.black)
                            .font(.system(size: 20, weight: .bold))
                            .padding(.trailing, 20)
                    }
                    .frame(width: 350, height: 70)
                    .background(RoundedRectangle(cornerRadius: 20) .fill(Color.white))
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                    .offset(y: -20)
                }
                    
            }
            .frame(width: screen.width)
            .navigationBarTitle(Text("Vaccinare"))
        }
        .frame(width: screen.width, height: screen.height)
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}

struct VaccinationView_Previews: PreviewProvider {
    static var previews: some View {
        VaccinationView()
            .addPartialSheet()
            .navigationViewStyle(StackNavigationViewStyle())
            .environmentObject(PartialSheetManager())
    }
}

struct resurseUtile : Identifiable {
    var id = UUID()
    var titlu: String
    var image: String
    var link: String
}

let resurseUtileArray = [
    resurseUtile(titlu: "Top 10 informații sigure", image: "top10infosigure_UY", link: "https://vaccinare-covid.gov.ro/vaccinarea-sars-cov-2/top-10-informatii-sigure/"),
    resurseUtile(titlu: "Top 10 informații înșelătoare", image: "top10infoinselatoare_UY", link: "https://vaccinare-covid.gov.ro/vaccinarea-sars-cov-2/top-10-informatii-inselatoare/"),
    resurseUtile(titlu: "Mic dicționar de vaccinare", image: "dictionarVaccinare_UY", link: "https://vaccinare-covid.gov.ro/resurse/mic-dictionar-de-vaccinare/")]
