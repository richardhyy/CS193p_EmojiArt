//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Richard on 1/23/21.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    
    @State private var chosenPalette: String = ""
    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        // use `id` arg so we don't have to extend String to be identifiable
                        ForEach(chosenPalette.map { String($0) }, id: \.self) { emoji in
                            Text(emoji)
                                .font(Font.system(size: defaultEmojiSize))
                                .onDrag { NSItemProvider(object: emoji as NSString ) }
                        }
                    }
                }
                .onAppear() { chosenPalette = document.defaultPalette }
                Button("Clear") {
                    document.clear()
                }
            }.padding(.horizontal)
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                        OptionalImage(uiImage: document.backgroundImage)
                            .scaleEffect(zoomScale)
                            .offset(panOffset)
                    )
                    //.gesture(singleTapToDeselectAll().exclusively(before: doubleTapToZoom(in: geometry.size))) // ❌ WRONG ORDER
                    .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: singleTapToDeselectAll()))
                    
                    if isLoading {
                        Image(systemName: "hourglass")
                            .imageScale(.large)
                            .spinning()
                    }
                    else {
                        ForEach(self.document.emojis) { emoji in
                            emojiView(emoji: emoji, geometry: geometry)
                        }
                    }
                }
                .clipped()
                .gesture(panGesture())
                .gesture(zoomGesture())
                .edgesIgnoringSafeArea([.horizontal, .bottom])
                .onReceive(document.$backgroundImage) { image in
                    zoomToFit(image, in: geometry.size)
                }
                .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                    var loc = geometry.convert(location, from: .global)
                    loc = CGPoint(x: loc.x - geometry.size.width/2, y: loc.y - geometry.size.height/2)
                    loc = CGPoint(x: loc.x - panOffset.width, y: loc.y - panOffset.height)
                    loc = CGPoint(x: loc.x / zoomScale, y: loc.y / zoomScale)
                    return self.drop(providers: providers, at: loc)
                }
            }
        }
    }
    
    @ViewBuilder
    func emojiView(emoji: EmojiArt.Emoji, geometry: GeometryProxy) -> some View {
        let fontSize = emoji.fontSize * zoomScale
        
        ZStack {
            if document.selectedEmojis.contains(matching: emoji) {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(Color(UIColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.5)))
                    .frame(width: fontSize + 4, height: fontSize + 4)
            }
            
            Text(emoji.text)
                .font(animatableWithSize: fontSize)
                .onTapGesture {
                    document.select(emoji)
                }
                .gesture(moveEmojiGesture(emoji))
            
            if document.selectedEmojis.contains(matching: emoji) {
                Image(systemName: "minus.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .offset(x: fontSize / 2 - fontSize * 0.1, y: -fontSize / 2 + fontSize * 0.1)
                    .onTapGesture {
                        document.removeEmoji(emoji)
                    }
            }
        }
        .position(self.position(for: emoji, in: geometry.size))
    }
    
    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }
    
    @State private var steadyStateZoomScale: CGFloat = 1.0
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    
    private var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }
    
    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            // the second para(gestureZoomScale) modified by `inout`
            // (CGFloat, inout State, inout Transaction)
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                if document.selectedEmojis.count == 0 { // No emoji selected
                    gestureZoomScale = latestGestureScale
                }
                else { // scale selected emojis
                    for emoji in document.selectedEmojis {
                        if (latestGestureScale > 1 && emoji.size < 150) || (latestGestureScale < 1 && emoji.size > 15) {
                            document.scaleEmoji(emoji, by: latestGestureScale)
                        }
                    }
                }
            }
            .onEnded { finalGestureScale in
                if document.selectedEmojis.count == 0 { // No emoji selected
                    steadyStateZoomScale *= finalGestureScale
                }
            }
    }
    
    private func singleTapToDeselectAll() -> some Gesture {
        TapGesture(count: 1)
            .onEnded() {
                document.deselectAll()
            }
    }
    
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }
    
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStatePanOffset = .zero
            steadyStateZoomScale = min(hZoom, vZoom)
        }
    }
    
    
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gesturePanOffset: CGSize = .zero
    
    private var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }
    
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { (latestDragGestureValue, gesturePanOffset, transaction) in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }
    
    
    private func moveEmojiGesture(_ emoji: EmojiArt.Emoji) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if (document.selectedEmojis.contains(matching: emoji)) {
                    for e in document.selectedEmojis {
                        document.moveEmoji(e, by: value.translation)
                    }
                }
                else {
                    document.moveEmoji(emoji, by: value.translation)
                }
            }
    }
    
    
    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + size.width/2, y: location.y + size.height/2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }
    
    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("Dropped \(url)")
            document.backgroundURL = url
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
