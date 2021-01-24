//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Richard on 1/23/21.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    private static let untitled = "EmojiArtDocument.Untitled"
    static let palette: String = "🐶😂🍧😓🧶🤔"
    
    @Published private var selectedEmojiIds = Set<Int>()
    
    var selectedEmojis:Set<EmojiArt.Emoji> {
        var selected = Set<EmojiArt.Emoji>()
        for id in selectedEmojiIds {
            selected.insert(emojiArt.emojis[emojiArt.emojis.firstIndex(ofId: id)!])
        }
        return selected
    }
    
    @Published private var emojiArt: EmojiArt = EmojiArt() {
        /* No longer needed: property observer not working bug has been fixed for @Published
         willSet {
            objectWillChange.send()
         }
         */
        didSet {
            //print("json = \(emojiArt.json?.utf8 ?? "nil")")
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
    }
    
    @Published private(set) var backgroundImage: UIImage?
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        fetchBackgroundImageData()
    }
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL {
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        if url == self.emojiArt.backgroundURL { // to make sure the image is what the user expected
                            self.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Intent(s)
    
    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(emoji, x: Int(location.x), y: Int(location.y), size: Int(size))
    }
    
    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.firstIndex(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrEven))
        }
    }
    
    func select(_ emoji: EmojiArt.Emoji) {
        if selectedEmojis.contains(matching: emoji) {
            selectedEmojiIds.remove(emoji.id)
        }
        else {
            selectedEmojiIds.insert(emoji.id)
        }
    }
    
    func deselectAll() {
        selectedEmojiIds.removeAll()
    }
    
    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }
    
    func removeEmoji(_ emoji: EmojiArt.Emoji) {
        if selectedEmojis.contains(matching: emoji) {
            selectedEmojiIds.remove(emoji.id)
        }
        emojiArt.removeEmoji(emoji)
    }
    
    func clear() {
        backgroundImage = nil
        emojiArt = EmojiArt()
    }
}

extension EmojiArt.Emoji {
    // Not violating MVVM since this is in the ViewModel
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}
