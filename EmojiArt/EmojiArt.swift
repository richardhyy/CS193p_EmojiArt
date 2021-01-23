//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Richard on 1/23/21.
//

import Foundation

struct EmojiArt {
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable {
        let id: Int // can use `= UUID()` alternatively
        let text: String
        var x: Int // offset from the center
        var y: Int // offset from the center
        var size: Int
        
        // `fileprivate` instead of `private`:
        // if we use `private`, it prevents us from init it from this file (addEmoji() no longer usable)
        fileprivate init(id: Int, text: String, x: Int, y: Int, size: Int) {
            self.id = id
            self.text = text
            self.x = x
            self.y = y
            self.size = size
        }
    }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(id: uniqueEmojiId, text: text, x: x, y: y, size: size))
    }
}
