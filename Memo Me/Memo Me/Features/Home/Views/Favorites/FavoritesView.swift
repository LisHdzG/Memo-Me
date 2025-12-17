//
//  FavoritesView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @ObservedObject private var spaceSelectionService = SpaceSelectionService.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showFiltersSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.ghostWhite)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("My Memos")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color("DeepSpace"))
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        if !viewModel.favoriteContacts.isEmpty {
                            VStack(spacing: 12) {
                                SearchBar(
                                    searchText: $viewModel.searchText,
                                    hasActiveFilters: viewModel.hasActiveFilters,
                                    showFiltersSheet: $showFiltersSheet
                                ) {
                                    viewModel.filterContacts(searchText: viewModel.searchText)
                                } onClearFilters: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        viewModel.clearAllFilters()
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                if viewModel.hasFilterOptions && viewModel.hasActiveFilters {
                                    FilterCategoriesView(viewModel: viewModel)
                                        .padding(.horizontal, 20)
                                        .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.hasActiveFilters)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    if viewModel.isLoading && !viewModel.hasLoadedOnce {
                        Spacer()
                        LoaderView()
                        Spacer()
                    } else if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(.electricRuby).opacity(0.9))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .shadow(color: Color(.electricRuby).opacity(0.3), radius: 8, x: 0, y: 4)
                    } else if !viewModel.favoriteContacts.isEmpty {
                    if viewModel.filteredContacts.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                
                                Image("MemoMeFavs")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 150)
                                    .opacity(0.5)
                                
                                Text("No results with these filters")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color("DeepSpace"))
                                
                                Text("Try exploring your space and find someone who matches these vibes or notes.")
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(.primaryDark.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                                
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.filteredContacts) { favoriteContact in
                                        FavoriteContactCard(
                                            favoriteContact: favoriteContact,
                                            viewModel: viewModel
                                        )
                                        .transition(.asymmetric(
                                            insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)
                                        ))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 40)
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.filteredContacts.count)
                        }
                    } else {
                        VStack(spacing: 20) {
                            Spacer()
                            
                            Image("MemoMeFavs")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                                .opacity(0.5)
                            
                            Text("No memos yet")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(Color("DeepSpace"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How to add memos:")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primaryDark.opacity(0.75))
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("1. Go to your space")
                                    Text("2. Did you find someone?")
                                    Text("3. Add a note, a vibe, or tap the star — it will be added to your memos")
                                }
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 32)
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
                .navigationDestination(isPresented: $viewModel.showContactDetail) {
                    if let contact = viewModel.selectedContact {
                        ContactDetailPageView(
                            user: viewModel.selectedUser,
                            contact: contact,
                            spaceId: nil as String?
                        )
                    } else {
                        EmptyView()
                    }
                }
            }
            .task {
                if let userId = authManager.currentUser?.id {
                    await viewModel.loadFavoriteContacts(userId: userId)
                }
            }
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .sheet(isPresented: $showFiltersSheet) {
                FiltersSheetView(viewModel: viewModel)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.favoriteContacts.count + viewModel.filteredContacts.count)
        }
    }
    
    struct SearchBar: View {
        @Binding var searchText: String
        var hasActiveFilters: Bool
        @Binding var showFiltersSheet: Bool
        var onSearch: () -> Void
        var onClearFilters: () -> Void
        @FocusState private var isSearchFocused: Bool
        
        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primaryDark.opacity(0.5))
                
                TextField("Search by name, vibe, space...", text: $searchText)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Color("DeepSpace"))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isSearchFocused)
                    .onSubmit {
                        onSearch()
                    }
                    .onChange(of: searchText) { _, newValue in
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
                
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showFiltersSheet = true
                    }
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
    
    struct FilterCategoriesView: View {
        @ObservedObject var viewModel: FavoritesViewModel
        
        var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if !viewModel.availableVibes.isEmpty {
                        ForEach(viewModel.availableVibes, id: \.id) { vibe in
                            FilterChip(
                                title: "\(vibe.emoji) \(vibe.name)",
                                isSelected: viewModel.selectedVibeFilter == vibe.id,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if viewModel.selectedVibeFilter == vibe.id {
                                            viewModel.selectedVibeFilter = nil
                                        } else {
                                            viewModel.selectedVibeFilter = vibe.id
                                        }
                                        viewModel.applyFilters()
                                    }
                                }
                            )
                        }
                    }
                    
                    if !viewModel.availableSpaces.isEmpty {
                        ForEach(viewModel.availableSpaces, id: \.self) { space in
                            FilterChip(
                                title: "📍 \(space)",
                                isSelected: viewModel.selectedSpaceFilter == space,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if viewModel.selectedSpaceFilter == space {
                                            viewModel.selectedSpaceFilter = nil
                                        } else {
                                            viewModel.selectedSpaceFilter = space
                                        }
                                        viewModel.applyFilters()
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    struct FilterChip: View {
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
        }
    }
    
    struct FavoriteContactCard: View {
        let favoriteContact: FavoriteContact
        @ObservedObject var viewModel: FavoritesViewModel
        @State private var isPressed: Bool = false
        
        private let noteService = ContactNoteService.shared
        private let userService = UserService()
        
        var contact: Contact {
            favoriteContact.contact
        }
        
        var vibes: [String] {
            guard let userId = contact.userId else { return [] }
            return viewModel.getVibes(for: userId)
        }
        
        var body: some View {
            Button(action: {
                Task {
                    viewModel.selectedContact = contact
                    if let userId = contact.userId {
                        viewModel.selectedUser = try? await userService.getUser(userId: userId)
                    }
                    viewModel.showContactDetail = true
                }
            }) {
                HStack(spacing: 16) {
                    AsyncImageView(
                        imageUrl: contact.imageUrl,
                        placeholderText: contact.name,
                        contentMode: .fill,
                        size: 64
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color("DeepSpace"), style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
                    )
                    .shadow(color: Color("DeepSpace").opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text(contact.name)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(Color("DeepSpace"))
                            .lineLimit(1)
                        
                        if !vibes.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(vibes.prefix(2), id: \.self) { vibeId in
                                    if let vibe = ContactVibeService.availableVibes.first(where: { $0.id == vibeId }) {
                                        HStack(spacing: 4) {
                                            Text(vibe.emoji)
                                                .font(.system(size: 11))
                                            Text(vibe.name)
                                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                        }
                                        .foregroundColor(Color("DeepSpace"))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color("DeepSpace").opacity(0.12),
                                                            Color("DeepSpace").opacity(0.06)
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color("DeepSpace").opacity(0.15), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 6) {
                            Text("Met at")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.55))
                            Text(favoriteContact.spaceName)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.75))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primaryDark.opacity(0.3))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
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
                .shadow(color: Color("DeepSpace").opacity(0.08), radius: 12, x: 0, y: 4)
                .shadow(color: Color("DeepSpace").opacity(0.03), radius: 4, x: 0, y: 2)
                .scaleEffect(isPressed ? 0.98 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = false
                        }
                    }
            )
        }
    }
    
    struct FiltersSheetView: View {
        @ObservedObject var viewModel: FavoritesViewModel
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationStack {
                ZStack {
                    Color(.ghostWhite)
                        .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Search & filter your memos")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color("DeepSpace"))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                            
                            Text("Narrow your memos by vibes or spaces. Tap to select filters and apply.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.7))
                                .padding(.horizontal, 20)
                            
                            if !viewModel.availableVibes.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Vibes")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(Color("DeepSpace"))
                                        .padding(.horizontal, 20)
                                    
                                    FlowLayout(spacing: 12) {
                                        ForEach(viewModel.availableVibes, id: \.id) { vibe in
                                            FilterPill(
                                                title: "\(vibe.emoji) \(vibe.name)",
                                                isSelected: viewModel.selectedVibeFilters.contains(vibe.id),
                                                action: {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        if viewModel.selectedVibeFilters.contains(vibe.id) {
                                                            viewModel.selectedVibeFilters.removeAll { $0 == vibe.id }
                                                        } else {
                                                            viewModel.selectedVibeFilters.append(vibe.id)
                                                        }
                                                        viewModel.applyFilters()
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            if !viewModel.availableSpaces.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Spaces")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(Color("DeepSpace"))
                                        .padding(.horizontal, 20)
                                    
                                    FlowLayout(spacing: 12) {
                                        ForEach(viewModel.availableSpaces, id: \.self) { space in
                                            FilterPill(
                                                title: "📍 \(space)",
                                                isSelected: viewModel.selectedSpaceFilters.contains(space),
                                                action: {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        if viewModel.selectedSpaceFilters.contains(space) {
                                                            viewModel.selectedSpaceFilters.removeAll { $0 == space }
                                                        } else {
                                                            viewModel.selectedSpaceFilters.append(space)
                                                        }
                                                        viewModel.applyFilters()
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            Spacer()
                                .frame(height: 40)
                        }
                        .padding(.top, 20)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.clearAllFilters()
                            }
                        }) {
                            Image(systemName: "eraser.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(viewModel.hasActiveFilters ? Color("DeepSpace") : Color("DeepSpace").opacity(0.4))
                        }
                        .disabled(!viewModel.hasActiveFilters)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Filter") {
                            dismiss()
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("DeepSpace"))
                    }
                }
            }
        }
    }
    
    struct FilterPill: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? .white : Color("DeepSpace"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
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
                            .stroke(isSelected ? Color.clear : Color("DeepSpace").opacity(0.2), lineWidth: 1.5)
                    )
                    .scaleEffect(isSelected ? 1.05 : 1.0)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    }
}
