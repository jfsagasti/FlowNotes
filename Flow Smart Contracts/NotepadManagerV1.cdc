pub contract NotepadManagerV1 {

    pub var numberOfNotepadsCreated: UInt64

	pub resource Note {
        pub(set) var title: String
        pub(set) var body: String

        init(title: String, body: String) {
            self.title = title 
            self.body = body
        }
	}

    pub struct NoteDTO {
        pub let noteID: UInt64
        pub let title: String
        pub let body: String

        init(noteID: UInt64, title: String, body: String) {
            self.noteID = noteID
            self.title = title 
            self.body = body
        }
    }

	pub resource Notepad {
        pub var notes: @{UInt64 : Note}

        init() {
            self.notes <- {}
        }

        destroy() {
            destroy self.notes
        }

        pub fun note(noteID: UInt64): NoteDTO {
            var note <- self.notes.remove(key: noteID)!
            let noteDTO = NoteDTO(noteID: noteID, title: note.title, body: note.body)
            
            let oldNote <- self.notes[note.uuid] <- note
            destroy oldNote
            return noteDTO
        }

        pub fun allNotes(): [NoteDTO] {
            var allNotes: [NoteDTO] = []
            for key in self.notes.keys {
                allNotes.append(self.note(noteID: key))
            }

            return allNotes
        }

        pub fun addNote(title: String, body: String) {
            let note <- create Note(title: title, body: body)

            let oldNote <- self.notes[note.uuid] <- note
            destroy oldNote
        }

        pub fun editNote(noteID: UInt64, newTitle: String, newBody: String) {
            let oldNote <- self.notes.insert(key: noteID, <- create Note(title: newTitle, body: newBody))
            destroy oldNote
        }

        pub fun deleteNote(noteID: UInt64) {
            let note <- self.notes.remove(key: noteID)
            destroy note
        }
	}

    init() {
        self.numberOfNotepadsCreated = 0
    }

    pub fun createNotepad(): @Notepad {
        self.numberOfNotepadsCreated = self.numberOfNotepadsCreated + 1
        return <- create Notepad()
    }

    pub fun deleteNotepad(notepad: @Notepad) {
        self.numberOfNotepadsCreated = self.numberOfNotepadsCreated > 0 ? self.numberOfNotepadsCreated - 1 : 0
        destroy notepad
    }
}