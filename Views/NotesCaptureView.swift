import SwiftUI
import CoreData

struct NotesCaptureView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedTab: Int
    
    @State private var noteText = ""
    @State private var currentNote: Note?
    @State private var pullDownOffset: CGFloat = 0
    @State private var isCreatingNewNote = false
    @FocusState private var isTextFieldFocused: Bool
    
    private let pullDownThreshold: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    TextEditor(text: $noteText)
                        .focused($isTextFieldFocused)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .onChange(of: noteText) { _, newValue in
                            saveNoteContent()
                        }
                        .onAppear {
                            loadCurrentNote()
                            isTextFieldFocused = true
                        }
                        .onChange(of: selectedTab) { _, newValue in
                            if newValue == 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isTextFieldFocused = true
                                }
                            }
                        }
                }
                .offset(y: pullDownOffset)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: pullDownOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.location.y < geometry.size.height * 0.3 && value.translation.y > 0 {
                                pullDownOffset = min(value.translation.y, pullDownThreshold * 1.5)
                            }
                        }
                        .onEnded { value in
                            if value.location.y < geometry.size.height * 0.3 && value.translation.y > pullDownThreshold {
                                createNewNote()
                            }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                pullDownOffset = 0
                            }
                        }
                )
            }
        }
    }
    
    private func loadCurrentNote() {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Note.modifiedAt, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let notes = try viewContext.fetch(request)
            if let note = notes.first {
                currentNote = note
                noteText = note.wrappedContent
            } else {
                createNewNote()
            }
        } catch {
            print("Error loading current note: \(error)")
            createNewNote()
        }
    }
    
    private func saveNoteContent() {
        guard let note = currentNote else { return }
        
        note.content = noteText
        note.modifiedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving note: \(error)")
        }
    }
    
    private func createNewNote() {
        if let currentNote = currentNote, !currentNote.wrappedContent.isEmpty {
            saveNoteContent()
        }
        
        let newNote = Note(context: viewContext)
        newNote.id = UUID()
        newNote.content = ""
        newNote.createdAt = Date()
        newNote.modifiedAt = Date()
        
        do {
            try viewContext.save()
            currentNote = newNote
            noteText = ""
            isTextFieldFocused = true
        } catch {
            print("Error creating new note: \(error)")
        }
    }
}

#Preview {
    NotesCaptureView(selectedTab: .constant(0))
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}