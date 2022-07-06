//
//  NoteEditorView.swift
//  FlowNotes
//
//  Created by Juan Sagasti on 20/6/22.
//  Copyright © 2022 The Agile Monkeys. All rights reserved.
//

import SwiftUI

struct NoteEditorView: View {
    
    @EnvironmentObject private var vm: MyNotesVM
    @Environment(\.dismiss) private var dismiss

    @State private var noteTitle = ""
    @State private var noteBody = ""
    
    private var canSaveNote: Bool { !noteTitle.isEmpty && !noteBody.isEmpty}
    
    private var saveButton: some View {
        Button("Save") {
            vm.createNote(title: noteTitle, body: noteBody)
            dismiss()
        }
        .opacity(canSaveNote ? 1 : 0.5)
        .disabled(!canSaveNote)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    TextField("Title", text: $noteTitle)
                        .foregroundColor(.black)
                        .font(.body.weight(.bold))
                        .accentColor(.black)
                        .padding(.vertical, 7)
                    
                    TextField("Body", text: $noteBody)
                        .foregroundColor(.black)
                        .accentColor(.black)
                        .padding(.vertical, 7)
                }
                .padding(.horizontal)
                .background(UI.flowGreen.opacity(0.5))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New note")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: saveButton)
        }
        .tint(UI.flowGreen)
    }
}

struct NoteEditor_Previews: PreviewProvider {
    static var previews: some View {
        NoteEditorView()
            .preferredColorScheme(.dark)
            .environmentObject(MyNotesVM())
    }
}
