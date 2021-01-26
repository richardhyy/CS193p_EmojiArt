//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Richard on 1/23/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    let store = EmojiArtDocumentStore(named: "Emoji Art")
    
    init() {
        
    }
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
            //EmojiArtDocumentView(document: EmojiArtDocument())
        }
    }
}
