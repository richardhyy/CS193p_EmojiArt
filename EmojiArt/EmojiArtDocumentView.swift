//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Richard on 1/23/21.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    // use `id` arg so we don't have to extend String to be identifiable
                    ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) { emoji in
                        Text(emoji)
                            .font(Font.system(size: defaultEmojiSize))
                            .onDrag { NSItemProvider(object: emoji as NSString ) }
                    }
                }
            }
            .padding(.horizontal)
            GeometryReader { geometry in
                ZStack {
                Rectangle().foregroundColor(.white).overlay(
                    Group {
                        if self.document.backgroundImage != nil {
                            Image(uiImage: self.document.backgroundImage!)
                        }
                    }
                )
                    .edgesIgnoringSafeArea([.horizontal, .bottom])
                    .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                        var loc = geometry.convert(location, from: .global)
                        loc = CGPoint(x: loc.x - geometry.size.width/2, y: loc.y - geometry.size.height/2)
                        return self.drop(providers: providers, at: loc)
                    }
                    
                    ForEach(self.document.emojis) { emoji in
                        Text(emoji.text)
                            .font(self.font(for: emoji))
                            .position(self.position(for: emoji, in: geometry.size))
                    }
                }
            }
        }
    }
    
    private func font(for emoji: EmojiArt.Emoji) -> Font {
        Font.system(size: emoji.fontSize)
    }
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        CGPoint(x: emoji.location.x + size.width/2, y: emoji.location.y + size.height/2)
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("Dropped \(url)")
            document.setBackgroundURL(url)
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }
    
    private let defaultEmojiSize: CGFloat = 40
}

/* We no longer need this because we utilized `id: \.self`
extension String: Identifiable {
    public var id: String { return self }
}
*/

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
