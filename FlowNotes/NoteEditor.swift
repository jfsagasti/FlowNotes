//
//  NoteEditor.swift
//  FlowNotes
//
//  Created by Juan Sagasti on 20/6/22.
//  Copyright © 2022 The Agile Monkeys. All rights reserved.
//

import SwiftUI

struct NoteEditor: View {
    
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
                        .padding(.vertical, 7)
                    
                    TextField("Body", text: $noteBody)
                        .padding(.vertical, 7)
                }
                .padding(.horizontal)
                .background(Color.yellow.opacity(0.5))
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("New note")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: saveButton)
        }
    }
}

struct NoteEditor_Previews: PreviewProvider {
    static var previews: some View {
        NoteEditor().environmentObject(MyNotesVM())
    }
}
