//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Richard on 1/23/21.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: EmojiArtDocument())
        }
    }
}
