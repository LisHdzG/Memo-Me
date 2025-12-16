//
//  ContactDetailSheet.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct ContactDetailPageView: View {
    let user: User?
    let contact: Contact
    let spaceId: String?
    
    @State private var noteText: String = ""
    @State private var isEditingNote: Bool = false
    @State private var isFavorite: Bool = false
    @State private var hasNote: Bool = false
    @State private var showImagePreview: Bool = false
    @State private var previewImage: UIImage?
    @State private var showRemoveFavoriteAlert: Bool = false
    @State private var selectedVibes: [String] = []
    @State private var hasVibes: Bool = false
    
    private let noteService = ContactNoteService.shared
    private let vibeService = ContactVibeService.shared
    
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
            Color(.ghostWhite)
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack(alignment: .center) {
                            Circle()
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                .foregroundColor(.primaryDark)
                                .frame(width: 144, height: 144)
                            
                            AsyncImageView(
                                imageUrl: photoUrl,
                                placeholderText: displayName,
                                contentMode: .fill,
                                size: 140
                            )
                            .clipShape(Circle())
                            .frame(width: 140, height: 140)
                            .contentShape(Circle())
                            .onTapGesture {
                                if let url = photoUrl, !url.isEmpty {
                                    loadPreviewImage(from: url)
                                    showImagePreview = true
                                }
                            }
                        }
                        .shadow(color: .primaryDark.opacity(0.15), radius: 12, x: 0, y: 4)
                        
                        VStack(spacing: 4) {
                            Text(displayName)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primaryDark)
                            
                            if let user = user {
                                if let country = user.country, !country.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.fill")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.primaryDark.opacity(0.5))
                                        Text("From \(country)")
                                            .font(.system(size: 15, weight: .regular, design: .rounded))
                                            .foregroundColor(.primaryDark.opacity(0.6))
                                            .fixedSize(horizontal: false, vertical: true)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 4)
                                }
                                
                                HStack(spacing: 10) {
                                    if let linkedinUrl = user.linkedinUrl, !linkedinUrl.isEmpty {
                                        SocialButton(imageName: "LinkedInLogo", url: linkedinUrl)
                                    }
                                    if let instagramUrl = user.instagramUrl, !instagramUrl.isEmpty {
                                        SocialButton(imageName: "InstagramLogo", url: instagramUrl)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    
                    if let userId = contactUserId {
                        VibeSection(
                            selectedVibes: $selectedVibes,
                            hasVibes: $hasVibes,
                            isFavorite: $isFavorite,
                            contactUserId: userId,
                            vibeService: vibeService
                        )
                        .padding(.horizontal, 20)
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
                    
                    if let user = user {
                        VStack(spacing: 20) {
                            if let areas = user.areas, !areas.isEmpty {
                                ProfileTagsRow(
                                    icon: "sparkles",
                                    prefix: "Passionate about",
                                    items: areas
                                )
                            }
                            
                            if let interests = user.interests, !interests.isEmpty {
                                ProfileTagsRow(
                                    icon: "heart.fill",
                                    prefix: "Loves",
                                    items: interests
                                )
                            }
                            
                            if (user.country == nil || user.country?.isEmpty == true) &&
                               (user.areas == nil || user.areas?.isEmpty == true) &&
                               (user.interests == nil || user.interests?.isEmpty == true) &&
                               (user.instagramUrl == nil || user.instagramUrl?.isEmpty == true) &&
                               (user.linkedinUrl == nil || user.linkedinUrl?.isEmpty == true) {
                                StoryTellingMessage(
                                    message: "This contact hasn't completed their profile yet",
                                    icon: "info.circle.fill"
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    } else {
                        StoryTellingMessage(
                            message: "Complete information not available",
                            icon: "exclamationmark.circle.fill"
                        )
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                        .frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditingNote {
                isEditingNote = false
            }
        }
        .onAppear {
            loadNote()
            loadVibes()
        }
        .onChange(of: contactUserId) { _, _ in
            loadNote()
            loadVibes()
        }
        .overlay {
            if showImagePreview, let image = previewImage {
                ImagePreviewOverlay(image: image, isPresented: $showImagePreview)
            }
        }
        .alert("Remove from favorites?", isPresented: $showRemoveFavoriteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                removeFavoriteAndNote()
            }
        } message: {
            Text("If you remove this contact from favorites, your note and vibe will also be deleted.")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if isFavorite {
                        if hasNote || hasVibes {
                            showRemoveFavoriteAlert = true
                        } else {
                            toggleFavorite()
                        }
                    } else {
                        toggleFavorite()
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isFavorite ? .pink : .primaryDark)
                }
            }
        }
    }
    
    private func toggleFavorite() {
        if isFavorite {
            noteService.removeFavorite(contactUserId: contactUserId ?? "")
            isFavorite = false
        } else {
            noteService.addFavorite(contactUserId: contactUserId ?? "")
            isFavorite = true
        }
    }
    
    private func removeFavoriteAndNote() {
        guard let userId = contactUserId else { return }
        noteService.removeFavorite(contactUserId: userId)
        noteService.deleteNote(contactUserId: userId)
        vibeService.deleteVibes(contactUserId: userId)
        isFavorite = false
        hasNote = false
        noteText = ""
        hasVibes = false
        selectedVibes = []
    }
    
    private func loadVibes() {
        guard let userId = contactUserId else {
            selectedVibes = []
            hasVibes = false
            return
        }
        
        let vibes = vibeService.getVibes(contactUserId: userId)
        selectedVibes = vibes
        hasVibes = !vibes.isEmpty
    }
    
    private func loadPreviewImage(from urlString: String) {
        Task {
            if let image = await ImageLoaderService.shared.loadImage(from: urlString) {
                await MainActor.run {
                    previewImage = image
                }
            }
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
        
        let hasNoteCheck = !noteText.isEmpty
        let hasVibesCheck = !vibeService.getVibes(contactUserId: userId).isEmpty
        isFavorite = noteService.isFavorite(contactUserId: userId) || hasNoteCheck || hasVibesCheck
        
        if (hasNoteCheck || hasVibesCheck) && !noteService.isFavorite(contactUserId: userId) {
            noteService.addFavorite(contactUserId: userId)
            isFavorite = true
        }
    }
}

struct VibeSection: View {
    @Binding var selectedVibes: [String]
    @Binding var hasVibes: Bool
    @Binding var isFavorite: Bool
    let contactUserId: String
    let vibeService: ContactVibeService
    
    @State private var isSelecting: Bool = false
    @State private var initialLoad: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if hasVibes && !isSelecting {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("DeepSpace").opacity(0.7))
                            .frame(width: 24, height: 24)
                        
                        Text("Vibe:")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.primaryDark.opacity(0.6))
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isSelecting = true
                            }
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color("DeepSpace"))
                                .padding(8)
                                .background(Color("DeepSpace").opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(selectedVibes, id: \.self) { vibeId in
                            if let vibe = ContactVibeService.availableVibes.first(where: { $0.id == vibeId }) {
                                HStack(spacing: 6) {
                                    Text(vibe.emoji)
                                        .font(.system(size: 14))
                                    Text(vibe.name)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color("DeepSpace"))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color("DeepSpace").opacity(0.15),
                                                    Color("DeepSpace").opacity(0.08)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color("DeepSpace").opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("DeepSpace").opacity(0.1),
                                            Color("DeepSpace").opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 2)
            } else {
                VibeSelectorView(
                    selectedVibes: $selectedVibes,
                    hasVibes: $hasVibes,
                    isSelecting: $isSelecting,
                    isFavorite: $isFavorite,
                    contactUserId: contactUserId,
                    vibeService: vibeService
                )
            }
        }
        .onAppear {
            if !hasVibes && initialLoad {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSelecting = true
                    initialLoad = false
                }
            }
        }
    }
}

struct VibeSelectorView: View {
    @Binding var selectedVibes: [String]
    @Binding var hasVibes: Bool
    @Binding var isSelecting: Bool
    @Binding var isFavorite: Bool
    let contactUserId: String
    let vibeService: ContactVibeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("DeepSpace").opacity(0.7))
                    .frame(width: 24, height: 24)
                
                Text("What vibe do they have?")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.6))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            if selectedVibes.count >= 2 {
                Text("You can select up to 2 vibes")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.5))
                    .padding(.horizontal, 16)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(ContactVibeService.availableVibes) { vibe in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            toggleVibe(vibe.id)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(vibe.emoji)
                                .font(.system(size: 14))
                            Text(vibe.name)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(selectedVibes.contains(vibe.id) ? .white : Color("DeepSpace"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedVibes.contains(vibe.id) ?
                                      LinearGradient(
                                          gradient: Gradient(colors: [
                                              Color("DeepSpace"),
                                              Color("DeepSpace").opacity(0.8)
                                          ]),
                                          startPoint: .topLeading,
                                          endPoint: .bottomTrailing
                                      ) :
                                      LinearGradient(
                                          gradient: Gradient(colors: [
                                              Color("DeepSpace").opacity(0.15),
                                              Color("DeepSpace").opacity(0.08)
                                          ]),
                                          startPoint: .topLeading,
                                          endPoint: .bottomTrailing
                                      )
                                )
                        )
                        .overlay(
                            Capsule()
                                .stroke(selectedVibes.contains(vibe.id) ? Color.clear : Color("DeepSpace").opacity(0.2), lineWidth: 1)
                        )
                    }
                    .disabled(selectedVibes.count >= 2 && !selectedVibes.contains(vibe.id))
                    .opacity(selectedVibes.count >= 2 && !selectedVibes.contains(vibe.id) ? 0.5 : 1.0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color("DeepSpace").opacity(0.1),
                                    Color("DeepSpace").opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func toggleVibe(_ vibeId: String) {
        if selectedVibes.contains(vibeId) {
            selectedVibes.removeAll(where: { $0 == vibeId })
            if selectedVibes.isEmpty {
                vibeService.deleteVibes(contactUserId: contactUserId)
                hasVibes = false
                let noteService = ContactNoteService.shared
                if noteService.getNote(contactUserId: contactUserId) == nil ||
                   noteService.getNote(contactUserId: contactUserId)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true {
                    noteService.removeFavorite(contactUserId: contactUserId)
                    isFavorite = false
                }
            } else {
                saveVibes()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSelecting = false
                    }
                }
            }
        } else {
            if selectedVibes.count < 2 {
                selectedVibes.append(vibeId)
                saveVibes()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSelecting = false
                    }
                }
            }
        }
    }
    
    private func saveVibes() {
        vibeService.saveVibes(contactUserId: contactUserId, vibes: selectedVibes)
        hasVibes = true
        isFavorite = true
    }
}

struct StoryTellingRow: View {
    let icon: String
    let prefix: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color("DeepSpace").opacity(0.7))
                .frame(width: 24, height: 24)
            
            HStack(spacing: 6) {
                Text(prefix)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primaryDark)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color("DeepSpace").opacity(0.1),
                                    Color("DeepSpace").opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct StoryTellingMessage: View {
    let message: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primaryDark.opacity(0.6))
            
            Text(message)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.primaryDark.opacity(0.7))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color("DeepSpace").opacity(0.1),
                                    Color("DeepSpace").opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct NoteSection: View {
    @Binding var noteText: String
    @Binding var isEditingNote: Bool
    @Binding var hasNote: Bool
    @Binding var isFavorite: Bool
    let contactUserId: String
    let noteService: ContactNoteService
    
    @FocusState private var isEditorFocused: Bool
    @State private var saveTask: Task<Void, Never>?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isEditingNote {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "note.text")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("DeepSpace").opacity(0.7))
                            .frame(width: 24, height: 24)
                        
                        Text("Note:")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundColor(.primaryDark.opacity(0.6))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    
                    TextEditor(text: $noteText)
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.primaryDark)
                        .frame(minHeight: 120)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .tint(.deepSpace)
                        .focused($isEditorFocused)
                        .onChange(of: noteText) { _, newValue in
                            saveTask?.cancel()
                            
                            saveTask = Task {
                                try? await Task.sleep(nanoseconds: 1_000_000_000)
                                
                                guard !Task.isCancelled else { return }
                                
                                await MainActor.run {
                                    saveNoteAutomatically(text: newValue)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                }
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("DeepSpace").opacity(0.1),
                                            Color("DeepSpace").opacity(0.05)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 2)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            } else {
                if hasNote {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "note.text")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color("DeepSpace").opacity(0.7))
                                .frame(width: 24, height: 24)
                            
                            Text("Note:")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.6))
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    isEditingNote = true
                                }
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color("DeepSpace"))
                                    .padding(8)
                                    .background(Color("DeepSpace").opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        
                        Text(noteText)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.primaryDark)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 10)
                            .padding(.bottom, 14)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color("DeepSpace").opacity(0.1),
                                                Color("DeepSpace").opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                    )
                    .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 2)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isEditingNote = true
                        }
                    }
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            isEditingNote = true
                        }
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(Color("DeepSpace").opacity(0.5))
                            
                            Text("Add your first impression")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("DeepSpace"))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            Color("DeepSpace").opacity(0.2),
                                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                                        )
                                )
                        )
                        .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 2)
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isEditingNote)
        .onChange(of: isEditingNote) { _, newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isEditorFocused = true
                }
            } else {
                saveTask?.cancel()
                saveNoteAutomatically(text: noteText)
                isEditorFocused = false
            }
        }
        .onDisappear {
            saveTask?.cancel()
            saveNoteAutomatically(text: noteText)
        }
    }
    
    private func saveNoteAutomatically(text: String) {
        let trimmedNote = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedNote.isEmpty {
            noteService.saveNote(contactUserId: contactUserId, note: trimmedNote)
            hasNote = true
            isFavorite = true
        } else {
            noteService.deleteNote(contactUserId: contactUserId)
            noteText = ""
            hasNote = false
            isFavorite = false
        }
    }
}
