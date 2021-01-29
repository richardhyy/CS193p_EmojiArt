//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Richard on 1/23/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
   
    let store: EmojiArtDocumentStore
    
    init() {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        store = EmojiArtDocumentStore(directory: url)
    }
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
            //EmojiArtDocumentView(document: EmojiArtDocument())
        }
    }
}
