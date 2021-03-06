//
//  MyNotesView.swift
//  FlowNotes
//
//  Created by Juan Sagasti on 24/5/22.
//  Copyright © 2022 The Agile Monkeys. All rights reserved.
//

import SwiftUI

struct MyNotesView: View {
    
    @StateObject private var vm: MyNotesVM
    
    @State private var isLoading = false
    @State private var isShowingNoteEditor = false
    @State private var isShowingErrorAlert = false
    
    init(vm: MyNotesVM) {
        _vm = .init(wrappedValue: vm)
    }
    
    private var signOutButton: some View {
        Button {
            vm.signOut()
        } label: {
            Label("Sign Out", systemImage: "person.crop.circle.badge.xmark")
        }
    }
    
    private var refreshNotepadButton: some View {
        Button {
            vm.queryNotes()
        } label: {
            Label("Refresh notepad", systemImage: "arrow.clockwise")
        }
    }
    
    private var deleteNotepadButton: some View {
        Button {
            vm.deleteNotepad()
        } label: {
            Label("Delete notepad", systemImage: "trash")
        }
        .opacity(vm.notes != nil ? 1 : 0)
        .disabled(vm.notes == nil)
    }
    
    private var moreOptionsButton: some View {
        Menu {
            refreshNotepadButton
            Divider()
            deleteNotepadButton
            Divider()
            signOutButton
        } label: {
            Image(systemName: "ellipsis")
        }
    }
    
    private var addNoteButton: some View {
        Button {
            isShowingNoteEditor = true
        } label: {
            Image(systemName: "plus")
        }
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                Group {
                    if let notes = vm.notes {
                        List {
                            ForEach(notes, id: \.id) { note in
                                NoteRow(note: note)
                                    .listRowBackground(Color.black)
                            }
                            .onDelete { index in
                                vm.deleteNote(atIndex: index.first)
                            }
                        }
                    
                    } else if vm.state == .loading {
                        EmptyView()
                    } else {
                        Text("Your notepad is empty 🤓\nAdd a new note from\nthe'＋'button")
                            .multilineTextAlignment(.center)
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                .navigationBarItems(leading: moreOptionsButton, trailing: addNoteButton)
                .navigationTitle("Flow Notes")
            }
            .tint(UI.flowGreen)
            
            ZStack {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .opacity(isLoading ? 0.7 : 0)
                
                ProgressView {
                    Text("On it! 🚀 \nPlease wait...")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                }
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .opacity(isLoading ? 1 : 0)
            }
        }
        .onChange(of: vm.state) { newValue in
            isLoading = newValue == .loading
            isShowingErrorAlert = newValue.isFailed
        }
        .alert(isPresented: $isShowingErrorAlert, content: {
            Alert(title: Text("Error!"),
                  message: Text(vm.state.errorMessage ?? "Unknown"),
                  dismissButton: .default(Text("OK"), action: {
                vm.currentErrorDidDismiss()
            }))
        })
        .sheet(isPresented: $isShowingNoteEditor) {
            isShowingNoteEditor = false
        } content: {
            NoteEditorView().environmentObject(vm)
        }
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(note.title)
                    .foregroundColor(.black)
                    .font(.body.weight(.bold))
                
                Text(note.body)
                    .foregroundColor(.black)
                    .font(.caption)
            }
            
            Spacer()
        }
        .padding()
        .background(UI.flowGreen)
        .cornerRadius(10)
    }
}

private struct PreviewWrapper: View {
    
    var vm = MyNotesVM()
    
    init() {
        vm.notes = [Note(id: 0, title: "This is a great note", body: "This is the body of a great note."),
                    Note(id: 1, title: "Another note", body: "The best body that was ever written.")]
    }
    
    var body: some View {
        MyNotesView(vm: vm).preferredColorScheme(.dark)
    }
}

struct MyNotesView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
}
