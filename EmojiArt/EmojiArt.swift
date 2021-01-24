//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Richard on 1/23/21.
//

import Foundation

// Codable = Encodable&Decodable
struct EmojiArt: Codable {
    var backgroundURL: URL?
    var emojis = [Emoji]()
    
    struct Emoji: Identifiable, Codable, Hashable {
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
    
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    // question mark after `init`: failable initializer
    // which may return `nil`
    init?(json: Data?) {
        if json != nil, let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: json!) {
            self = newEmojiArt // can assign a new value because it's a struct which represents a value
        } else {
            return nil
        }
    }
    
    init() {
        
    }
    
    private var uniqueEmojiId = 0
    
    mutating func addEmoji(_ text: String, x: Int, y: Int, size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(id: uniqueEmojiId, text: text, x: x, y: y, size: size))
    }
    
    mutating func removeEmoji(_ emoji: Emoji) {
        emojis.remove(at: emojis.firstIndex(matching: emoji)!)
    }
}
