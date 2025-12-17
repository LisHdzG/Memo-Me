private struct SpaceBannerView: View {
    let imageUrl: String
    
    var body: some View {
        if let url = URL(string: imageUrl), !imageUrl.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    placeholder
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        } else {
            placeholder
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("DeepSpace").opacity(0.18),
                        Color("DeepSpace").opacity(0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.8))
            )
    }
}

import SwiftUI

struct ContactDetailView: View {
    let space: Space?
    
    @StateObject private var viewModel = ContactDetailViewModel()
    @State private var rotationSpeed: Double = 1.5
    @State private var isAutoRotating: Bool = true
    @State private var selectedContact: Contact?
    @State private var selectedUser: User?
    @State private var showQRCode: Bool = false
    @State private var showLeaveSpaceAlert: Bool = false
    @State private var isLeavingSpace: Bool = false
    @State private var layoutMode: ContactLayoutMode = .sphere
    @State private var searchText: String = ""
    @State private var selectedVibeFilter: String?
    @State private var showFiltersBar: Bool = false
    @State private var isSpaceInfoExpanded: Bool = true
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    @EnvironmentObject var authManager: AuthenticationManager
    
    init(space: Space? = nil) {
        self.space = space
    }
    
    var body: some View {
        ZStack {
            Color(.ghostWhite)
                .ignoresSafeArea()
            mainContent
        }
        .task(id: spaceSelectionService.selectedSpace?.spaceId) {
            viewModel.currentUserId = authManager.currentUser?.id
            let currentSpace = space ?? spaceSelectionService.selectedSpace

            await viewModel.loadContacts(for: currentSpace, forceReload: false)
        }
        .onChange(of: spaceSelectionService.selectedSpace) { oldValue, newValue in
            Task {
                await viewModel.loadContacts(for: newValue, forceReload: true)
            }
        }
        .onChange(of: authManager.currentUser?.id) { oldValue, newValue in
            viewModel.currentUserId = newValue
        }
        .onAppear {
            rotationSpeed = 1.5
            isAutoRotating = true
        }
        .overlay {
            if viewModel.canShowInitialLoader && viewModel.isLoading && viewModel.contacts.isEmpty {
                LoaderView()
            }
        }
        .sheet(isPresented: $showQRCode) {
            if let spaceCode = (space ?? spaceSelectionService.selectedSpace)?.code {
                QRCodeSheetView(code: spaceCode)
            }
        }
        .alert("Leave Space", isPresented: $showLeaveSpaceAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    await leaveSpace()
                }
            }
        } message: {
            Text("If you leave this space, no one will be able to view your profile in this context. You can always rejoin later.")
        }
    }
    
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if spaceSelectionService.selectedSpace != nil {
                    headerSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                errorMessageView
                contactsContent
            }
            
            if spaceSelectionService.selectedSpace != nil {
                VStack { Spacer() }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: spaceSelectionService.selectedSpace?.spaceId)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            if spaceSelectionService.selectedSpace != nil {
                VStack(spacing: 12) {
                    HStack {
                        Spacer()
                        changeSpaceButton
                    }
                    .padding(.horizontal, 20)
                    
                    spaceSummary
                    
                    if !viewModel.contacts.isEmpty {
                        filterBar
                    }
                    
                    HStack {
                        Spacer()
                        layoutToggleButton
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color(.ghostWhite))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: layoutMode)
    }
    
    private var changeSpaceButton: some View {
        NavigationLink(destination: SpacesListView(shouldDismissOnSelection: true)) {
            HStack(spacing: 6) {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 14, weight: .medium))
                Text("Spaces")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(Color("DeepSpace"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color("DeepSpace").opacity(0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var errorMessageView: some View {
        if let errorMessage = viewModel.errorMessage {
            Text(errorMessage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding()
                .background(Color(.electricRuby).opacity(0.9))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .shadow(color: Color(.electricRuby).opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private var contactsContent: some View {
        if spaceSelectionService.selectedSpace == nil {
            noSpaceSelectedView
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        } else if !viewModel.contacts.isEmpty {
            contactsPresentation
        } else {
            emptyContactsView
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }
    
    private var noSpaceSelectedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text("Are you lost?")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(Color("DeepSpace"))
            
            Image("MemoMeScared")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            
            Text("You have not selected a space")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color("DeepSpace"))
            
            Text("To view members and connect with them, you need to join a context.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.primaryDark.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, -10)
            
            NavigationLink(destination: SpacesListView(shouldDismissOnSelection: true)) {
                Text("Go to spaces")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color("DeepSpace"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.ghostWhite))
    }
    
    private var emptyContactsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.primaryDark.opacity(0.3))
            
            VStack(spacing: 12) {
                Text("No members yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(Color("DeepSpace"))
                
                Text("Only you are here. Share the QR code of this space and let others join!")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if (space ?? spaceSelectionService.selectedSpace)?.code != nil {
                Button(action: {
                    showQRCode = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Show QR Code")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("DeepSpace"),
                                Color("DeepSpace").opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: Color("DeepSpace").opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.ghostWhite))
    }
    
    private var leaveSpaceButton: some View {
        Button(action: {
            showLeaveSpaceAlert = true
        }) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primaryDark.opacity(0.6))
                .padding(8)
                .background(
                    Circle()
                        .fill(Color("DeepSpace").opacity(0.08))
                )
        }
        .disabled(isLeavingSpace)
    }
    
    private func leaveSpace() async {
        guard let currentSpace = space ?? spaceSelectionService.selectedSpace,
              let userId = authManager.currentUser?.id else {
            return
        }
        
        isLeavingSpace = true
        
        do {
            let spaceService = SpaceService()
            try await spaceService.leaveSpace(spaceId: currentSpace.spaceId, userId: userId)
            
            spaceSelectionService.clearSelectedSpace()
            ContactCacheService.shared.clearCache(for: currentSpace.spaceId)
            viewModel.reset()
            
            isLeavingSpace = false
        } catch {
            isLeavingSpace = false
            viewModel.errorMessage = "Error leaving space: \(error.localizedDescription)"
        }
    }
    
    private var contactsPresentation: some View {
        ZStack {
            Color(.ghostWhite)
                .ignoresSafeArea()
            
            Group {
                switch layoutMode {
                case .sphere:
            ContactSphereView(
                contacts: displayedContacts,
                rotationSpeed: $rotationSpeed,
                isAutoRotating: $isAutoRotating,
                onContactTapped: { contact in
                    handleContactSelection(contact)
                },
                memoProvider: { contact in
                    isMemo(contact)
                }
            )
                case .list:
                    ContactListView(
                        contacts: displayedContacts,
                        userProvider: { contact in
                            viewModel.getUser(for: contact)
                        },
                        memoProvider: { contact in
                            isMemo(contact)
                        },
                        onSelect: { contact in
                            handleContactSelection(contact)
                        }
                    )
                    .padding(.top, 6)
                }
            }
            .animation(.spring(response: 0.55, dampingFraction: 0.9), value: layoutMode)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .navigationDestination(item: $selectedContact) { contact in
            ContactDetailPageView(
                user: selectedUser,
                contact: contact,
                spaceId: space?.spaceId ?? spaceSelectionService.selectedSpace?.spaceId
            )
            .onDisappear {
                selectedContact = nil
                selectedUser = nil
            }
        }
        .onChange(of: selectedContact) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedUser = nil
                }
            }
        }
        .onChange(of: viewModel.contacts) { oldContacts, newContacts in
            if let current = selectedContact, !newContacts.contains(current) {
                selectedContact = nil
                selectedUser = nil
            }
        }
    }
    
    private var layoutToggleButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                toggleLayout()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(layoutMode == .sphere ? Color("DeepSpace") : Color("DeepSpace").opacity(0.45))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(layoutMode == .sphere ? Color.white : Color.white.opacity(0.7))
                            .shadow(color: Color("DeepSpace").opacity(layoutMode == .sphere ? 0.14 : 0.05), radius: 4, x: 0, y: 2)
                    )
                
                Image(systemName: "rectangle.grid.1x2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(layoutMode == .list ? Color("DeepSpace") : Color("DeepSpace").opacity(0.45))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(layoutMode == .list ? Color.white : Color.white.opacity(0.7))
                            .shadow(color: Color("DeepSpace").opacity(layoutMode == .list ? 0.14 : 0.05), radius: 4, x: 0, y: 2)
                    )
            }
            .padding(6)
            .background(
                Capsule(style: .continuous)
                    .fill(Color("DeepSpace").opacity(0.12))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color("DeepSpace").opacity(0.16), lineWidth: 1)
            )
            .shadow(color: Color("DeepSpace").opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var filterBar: some View {
        VStack(spacing: 10) {
            ContactsSearchBar(
                searchText: $searchText,
                hasActiveFilters: hasActiveFilters,
                onSearch: {},
                onClearFilters: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        clearFilters()
                    }
                },
                onToggleFilters: availableVibeFilters.isEmpty ? nil : {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                        showFiltersBar.toggle()
                    }
                }
            )
            
            if showFiltersBar, !availableVibeFilters.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableVibeFilters, id: \.id) { vibe in
                            FilterChip(
                                title: "\(vibe.emoji) \(vibe.name)",
                                isSelected: selectedVibeFilter == vibe.id
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    if selectedVibeFilter == vibe.id {
                                        selectedVibeFilter = nil
                                    } else {
                                        selectedVibeFilter = vibe.id
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func handleContactSelection(_ contact: Contact) {
        selectedUser = viewModel.getUser(for: contact)
        
        if selectedUser == nil, let userId = contact.userId {
            Task {
                do {
                    let userService = UserService()
                    let loadedUser = try await userService.getUser(userId: userId)
                    await MainActor.run {
                        selectedUser = loadedUser
                        selectedContact = contact
                    }
                } catch {
                    await MainActor.run {
                        selectedContact = contact
                    }
                }
            }
        } else {
            selectedContact = contact
        }
    }
    
    private func isMemo(_ contact: Contact) -> Bool {
        guard let userId = contact.userId else { return false }
        return ContactNoteService.shared.isFavorite(contactUserId: userId)
    }
    
    private var currentSpace: Space? {
        space ?? spaceSelectionService.selectedSpace
    }
    
    private var spaceSummary: some View {
        let bannerUrl = currentSpace?.bannerUrl ?? ""
        let description = currentSpace?.description.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let isOfficial = currentSpace?.isOfficial ?? false
        
        return VStack(spacing: 12) {
            Button(action: {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isSpaceInfoExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    SpaceBannerView(imageUrl: bannerUrl)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(currentSpace?.name ?? "Contacts")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("DeepSpace"))
                                .lineLimit(1)
                            
                            if isOfficial {
                                Label("Official", systemImage: "checkmark.seal.fill")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.18))
                                    )
                                    .foregroundColor(Color("DeepSpace"))
                            }
                        }
                        
                        if let types = currentSpace?.types, !types.isEmpty, let first = types.first {
                            HStack(spacing: 8) {
                                Label(first, systemImage: "leaf.fill")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.22))
                                    )
                                    .foregroundColor(Color("DeepSpace"))
                                
                                Spacer(minLength: 0)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSpaceInfoExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color("DeepSpace").opacity(0.8))
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.18))
                        )
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
            
            if isSpaceInfoExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(description.isEmpty ? "No description yet" : description)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.primaryDark.opacity(0.78))
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(spacing: 10) {
                        if let code = currentSpace?.code, !code.isEmpty {
                            Button(action: { showQRCode = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Compartir QR")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("DeepSpace"),
                                            Color("DeepSpace").opacity(0.9)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        leaveSpaceButton
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("DeepSpace"))
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("DeepSpace").opacity(0.12),
                                Color("DeepSpace").opacity(0.07)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.65))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color("DeepSpace").opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color("DeepSpace").opacity(0.07), radius: 12, x: 0, y: 6)
    }
    
    private var displayedContacts: [Contact] {
        viewModel.contacts.filter { contact in
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            contact.name.localizedCaseInsensitiveContains(searchText)
            
            let matchesVibe: Bool
            if let selected = selectedVibeFilter, let userId = contact.userId {
                let vibes = ContactVibeService.shared.getVibes(contactUserId: userId)
                matchesVibe = vibes.contains(selected)
            } else {
                matchesVibe = true
            }
            
            return matchesSearch && matchesVibe
        }
    }
    
    private var availableVibeFilters: [VibeOption] {
        var set: Set<String> = []
        var vibes: [VibeOption] = []
        for contact in viewModel.contacts {
            if let userId = contact.userId {
                let ids = ContactVibeService.shared.getVibes(contactUserId: userId)
                for id in ids {
                    if set.insert(id).inserted,
                       let vibe = ContactVibeService.availableVibes.first(where: { $0.id == id }) {
                        vibes.append(vibe)
                    }
                }
            }
        }
        return vibes
    }
    
    private var hasActiveFilters: Bool {
        !(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) || selectedVibeFilter != nil
    }
    
    private func clearFilters() {
        searchText = ""
        selectedVibeFilter = nil
    }
    
    private func toggleLayout() {
        layoutMode = layoutMode == .sphere ? .list : .sphere
    }
}

private enum ContactLayoutMode: String, CaseIterable, Identifiable {
    case sphere
    case list
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .sphere: return "Spheres"
        case .list: return "List"
        }
    }
    
    var iconName: String {
        switch self {
        case .sphere: return "sparkles"
        case .list: return "rectangle.grid.1x2.fill"
        }
    }
}

private struct ContactListView: View {
    let contacts: [Contact]
    let userProvider: (Contact) -> User?
    let memoProvider: (Contact) -> Bool
    let onSelect: (Contact) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(contacts, id: \.id) { contact in
                    let user = userProvider(contact)
                    ContactListRow(
                        contact: contact,
                        user: user,
                        isMemo: memoProvider(contact),
                        onTap: {
                            onSelect(contact)
                        }
                    )
                    .padding(.horizontal, 20)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }
}


private struct ContactListRow: View {
    let contact: Contact
    let user: User?
    let isMemo: Bool
    let onTap: () -> Void
    
    private var displayName: String {
        user?.name ?? contact.name
    }
    
    private var infoText: String {
        var parts: [String] = []
        
        if let country = user?.country, !country.isEmpty {
            parts.append(country)
        }
        
        if let area = user?.areas?.first, !area.isEmpty {
            parts.append(area)
        } else if let interest = user?.interests?.first, !interest.isEmpty {
            parts.append(interest)
        }
        
        return parts.isEmpty ? "No shared info yet" : parts.joined(separator: " • ")
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                AsyncImageView(
                    imageUrl: user?.photoUrl ?? contact.imageUrl,
                    placeholderText: displayName,
                    contentMode: .fill,
                    size: 64
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color("DeepSpace"), style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
                )
                .shadow(color: Color("DeepSpace").opacity(0.1), radius: 4, x: 0, y: 2)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(displayName)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("DeepSpace"))
                            .lineLimit(1)
                        
                        if isMemo {
                            Label("Memo", systemImage: "star.fill")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(Color("DeepSpace").opacity(0.12))
                                )
                                .foregroundColor(Color("DeepSpace"))
                        }
                    }
                    
                    Text(infoText)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.primaryDark.opacity(0.65))
                        .lineLimit(2)
                    
                    let instagram = user?.instagramUrl ?? ""
                    let linkedin = user?.linkedinUrl ?? ""
                    
                    if !instagram.isEmpty || !linkedin.isEmpty {
                        HStack(spacing: 6) {
                            if !instagram.isEmpty {
                                SocialPill(icon: "camera.fill", label: "Instagram")
                            }
                            if !linkedin.isEmpty {
                                SocialPill(icon: "link", label: "LinkedIn")
                            }
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primaryDark.opacity(0.35))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("DeepSpace").opacity(0.08),
                                        Color("DeepSpace").opacity(0.03)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.55),
                                Color("DeepSpace").opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color("DeepSpace").opacity(0.05), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct ContactsSearchBar: View {
    @Binding var searchText: String
    var hasActiveFilters: Bool
    var onSearch: () -> Void
    var onClearFilters: () -> Void
    var onToggleFilters: (() -> Void)?
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primaryDark.opacity(0.5))
            
            TextField("Search contacts...", text: $searchText)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(Color("DeepSpace"))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($isSearchFocused)
                .onSubmit {
                    onSearch()
                }
                .onChange(of: searchText) { _, _ in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onSearch()
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        searchText = ""
                        onSearch()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primaryDark.opacity(0.5))
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            if let toggleAction = onToggleFilters {
                Button(action: {
                    toggleAction()
                }) {
                    ZStack(alignment: .center) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(hasActiveFilters ? Color("DeepSpace") : Color("DeepSpace").opacity(0.6))
                        
                        if hasActiveFilters {
                            Circle()
                                .fill(Color(.electricRuby))
                                .frame(width: 8, height: 8)
                                .offset(x: 7, y: -7)
                        }
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: searchText.isEmpty)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : Color("DeepSpace"))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ?
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
                        .stroke(isSelected ? Color.clear : Color("DeepSpace").opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct SocialPill: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(Color("DeepSpace").opacity(0.08))
        )
        .foregroundColor(Color("DeepSpace"))
    }
}

