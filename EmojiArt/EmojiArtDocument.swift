//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Richard on 1/23/21.
//

import SwiftUI
import Combine

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
    
    @Published private var emojiArt: EmojiArt
    
    @Published private(set) var backgroundImage: UIImage?
    
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    
    private var autoSaveCancellable: AnyCancellable? // from framework `Combine` (import Combine)
    
    init() {
        emojiArt = EmojiArt(json: UserDefaults.standard.data(forKey: EmojiArtDocument.untitled)) ?? EmojiArt()
        autoSaveCancellable = $emojiArt.sink { emojiArt in
            UserDefaults.standard.set(emojiArt.json, forKey: EmojiArtDocument.untitled)
        }
        fetchBackgroundImageData()
    }
    
    private var fetchImageCancellable: AnyCancellable?
    
    private func fetchBackgroundImageData() {
        backgroundImage = nil
        if let url = emojiArt.backgroundURL {
            fetchImageCancellable?.cancel() // cancel the previous one if it exists
            
            let session = URLSession.shared
            let publisher = session.dataTaskPublisher(for: url)                                         // 🌟
                .map { data, urlResponse in UIImage(data: data) }
                .receive(on: DispatchQueue.main)
                .replaceError(with: nil) // Error => never
            fetchImageCancellable = publisher.assign(to: \.backgroundImage, on: self)
            // \.backgroundImage can be inferred as \EmojiArtDocument.backgroundImage
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
    
    var backgroundURL: URL? {
        get {
            emojiArt.backgroundURL
        }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
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
