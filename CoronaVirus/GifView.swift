//
//  GifView.swift
//  CoronaVirus
//
//  Created by Milovan on 01.04.2021.
//

import Foundation
import SwiftUI
import FLAnimatedImage

struct GifView: UIViewRepresentable {
    
    let animatedView = FLAnimatedImageView()
    var filename : String
    
    func makeUIView(context: UIViewRepresentableContext<GifView>) -> UIView {
        
        let view = UIView()
        //var path : String = Bundle.main.path(forResource: filename, ofType: "gif")!
        if let path = Bundle.main.path(forResource: filename, ofType: "gif"){
            let url = URL(fileURLWithPath: path)
            let gifData = try! Data(contentsOf: url)
            let gif = FLAnimatedImage(animatedGIFData: gifData)
            
            animatedView.animatedImage = gif
            animatedView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(animatedView)
            
            NSLayoutConstraint.activate([
                animatedView.heightAnchor.constraint(equalTo: view.heightAnchor),
                animatedView.widthAnchor.constraint(equalTo: view.widthAnchor)
            ])
            }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<GifView>) {
        
    }
}
