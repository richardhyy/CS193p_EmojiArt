//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Alan Richard on 1/26/21.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore
    
    @State private var editMode: EditMode = .inactive
    
    @State private var isShowingNameAlreadyTakenAlert = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(store.documents) { document in
                    NavigationLink(destination: EmojiArtDocumentView(document: document)
                                    .navigationTitle(store.name(for: document))
                                    .navigationBarTitleDisplayMode(.inline)
                    ) {
                        EditableText(store.name(for: document), isEditing: editMode.isEditing) { name in
                            if !store.setName(name, for: document) {
                                isShowingNameAlreadyTakenAlert = true
                            }
                        }
                        .alert(isPresented: $isShowingNameAlreadyTakenAlert, content: {
                            Alert(title: Text("Failed"), message: Text("The new name is already taken. Please choose a different name."))
                        })
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { store.documents[$0] }.forEach { document in
                        store.removeDocument(document)
                    }
                }
            }
            .navigationTitle(store.name)
            .navigationBarItems(
                leading: Button(action: {
                                            store.addDocument()
                                        },
                                label: {
                                            Image(systemName: "plus").imageScale(.large)
                                        }),
                trailing: EditButton()
            )
            .environment(\.editMode, $editMode)
        }
    }
}

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentChooser().environmentObject(EmojiArtDocumentStore())
    }
}
