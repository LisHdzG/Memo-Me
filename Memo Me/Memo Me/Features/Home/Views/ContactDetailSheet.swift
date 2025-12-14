//
//  ContactDetailSheet.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct ContactDetailSheet: View {
    let user: User?
    let contact: Contact
    let spaceId: String?
    @Environment(\.dismiss) private var dismiss
    
    @State private var noteText: String = ""
    @State private var isEditingNote: Bool = false
    @State private var isFavorite: Bool = false
    @State private var hasNote: Bool = false
    
    private let noteService = ContactNoteService.shared
    
    init(user: User? = nil, contact: Contact, spaceId: String? = nil) {
        self.user = user
        self.contact = contact
        self.spaceId = spaceId
    }
    
    var displayName: String {
        user?.name ?? contact.name
    }
    
    var photoUrl: String? {
        user?.photoUrl ?? contact.imageUrl
    }
    
    var contactUserId: String? {
        contact.userId ?? user?.id
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("PurpleGradientTop"),
                    Color("PurpleGradientMiddle"),
                    Color("PurpleGradientBottom")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        ZStack(alignment: .topTrailing) {
                            AsyncImageView(
                                imageUrl: photoUrl,
                                placeholderText: displayName,
                                contentMode: .fill,
                                size: 140
                            )
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 4)
                            )
                            
                            if isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.pink)
                                    .padding(8)
                                    .background(
                                        Circle()
                                            .fill(Color.white.opacity(0.9))
                                    )
                                    .offset(x: 10, y: -10)
                            }
                        }
                        
                        Text(displayName)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)
                    
                    if let user = user {
                        VStack(spacing: 20) {
                            if let country = user.country, !country.isEmpty {
                                InfoRow(
                                    title: "País",
                                    value: country,
                                    icon: "flag.fill"
                                )
                            }
                            
                            if let areas = user.areas, !areas.isEmpty {
                                InfoRow(
                                    title: "Áreas de Expertise",
                                    value: areas.joined(separator: ", "),
                                    icon: "briefcase.fill"
                                )
                            }
                            
                            if let interests = user.interests, !interests.isEmpty {
                                InfoRow(
                                    title: "Intereses",
                                    value: interests.joined(separator: ", "),
                                    icon: "heart.fill"
                                )
                            }
                            
                            if let instagramUrl = user.instagramUrl, !instagramUrl.isEmpty {
                                LinkRow(
                                    title: "Instagram",
                                    value: instagramUrl,
                                    url: instagramUrl,
                                    icon: "camera.fill"
                                )
                            }
                            
                            if let linkedinUrl = user.linkedinUrl, !linkedinUrl.isEmpty {
                                LinkRow(
                                    title: "LinkedIn",
                                    value: linkedinUrl,
                                    url: linkedinUrl,
                                    icon: "briefcase.fill"
                                )
                            }
                            
                            if (user.country == nil || user.country?.isEmpty == true) &&
                               (user.areas == nil || user.areas?.isEmpty == true) &&
                               (user.interests == nil || user.interests?.isEmpty == true) &&
                               (user.instagramUrl == nil || user.instagramUrl?.isEmpty == true) &&
                               (user.linkedinUrl == nil || user.linkedinUrl?.isEmpty == true) {
                                InfoMessage(
                                    message: "Este contacto aún no ha completado su perfil",
                                    icon: "info.circle.fill"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        InfoMessage(
                            message: "Información completa no disponible",
                            icon: "exclamationmark.circle.fill"
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    if let userId = contactUserId {
                        NoteSection(
                            noteText: $noteText,
                            isEditingNote: $isEditingNote,
                            hasNote: $hasNote,
                            isFavorite: $isFavorite,
                            contactUserId: userId,
                            noteService: noteService
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            loadNote()
        }
        .onChange(of: contactUserId) { _, _ in
            loadNote()
        }
    }
    
    private func loadNote() {
        guard let userId = contactUserId else {
            noteText = ""
            hasNote = false
            isFavorite = false
            return
        }
        
        if let note = noteService.getNote(contactUserId: userId) {
            noteText = note
            hasNote = true
        } else {
            noteText = ""
            hasNote = false
        }
        
        isFavorite = noteService.isFavorite(contactUserId: userId)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(value)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct LinkRow: View {
    let title: String
    let value: String
    let url: String
    let icon: String
    
    private let socialMediaService = SocialMediaService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Button(action: {
                if title.lowercased().contains("instagram") {
                    socialMediaService.openInstagram(urlString: url)
                } else if title.lowercased().contains("linkedin") {
                    socialMediaService.openLinkedIn(urlString: url)
                } else {
                    if let urlObj = URL(string: url) {
                        UIApplication.shared.open(urlObj)
                    }
                }
            }) {
                HStack {
                    Text(value)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.blue.opacity(0.9))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14))
                        .foregroundColor(.blue.opacity(0.9))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

struct InfoMessage: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.7))
            
            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

struct NoteSection: View {
    @Binding var noteText: String
    @Binding var isEditingNote: Bool
    @Binding var hasNote: Bool
    @Binding var isFavorite: Bool
    let contactUserId: String
    let noteService: ContactNoteService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                Text("Mi Nota Personal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                if hasNote && !isEditingNote {
                    Button(action: {
                        isEditingNote = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
            
            if isEditingNote {
                VStack(spacing: 12) {
                    TextEditor(text: $noteText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .scrollContentBackground(.hidden)
                    
                    HStack(spacing: 12) {
                        if hasNote {
                            Button(action: {
                                deleteNote()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                    Text("Eliminar")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.7))
                                .cornerRadius(12)
                            }
                        }
                        
                        Button(action: {
                            saveNote()
                        }) {
                            HStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14))
                                Text("Guardar")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
            } else {
                if hasNote {
                    Text(noteText)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .onTapGesture {
                            isEditingNote = true
                        }
                } else {
                    Button(action: {
                        isEditingNote = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 16))
                            Text("Agregar nota personal")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }
    
    private func saveNote() {
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedNote.isEmpty {
            noteService.saveNote(contactUserId: contactUserId, note: trimmedNote)
            hasNote = true
            isFavorite = true
        } else {
            deleteNote()
        }
        
        isEditingNote = false
    }
    
    private func deleteNote() {
        noteService.deleteNote(contactUserId: contactUserId)
        noteText = ""
        hasNote = false
        isFavorite = false
        isEditingNote = false
    }
}

