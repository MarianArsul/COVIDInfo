//
//  ContentView.swift
//  WebScrape
//
//  Created by Milovan on 01.05.2021.
//

import UIKit
import SwiftSoup
import WebKit
import Foundation

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            let content = try String(contentsOf: URL(string: "https://stirioficiale.ro/informatii")!)
            let doc: Elements = try SwiftSoup.parse(content).select("article")
            for article: Element in doc.array() {
                print(article)
            }
        }
        catch Exception.Error(type: let type, Message: let message) {
            print(type)
            print(message)
        }
        catch {
            print("error")
        }
    }
}
