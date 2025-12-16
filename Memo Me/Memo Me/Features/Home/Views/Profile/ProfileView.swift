//
//  ProfileView.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile: Bool = false
    @State private var showDeleteAccountAlert: Bool = false
    @State private var showSignOutAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.ghostWhite)
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        HStack(spacing: 6) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(.primaryDark.opacity(0.4))
                            
                            Text("This is how others see your profile")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.5))
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                        
                        let photoUrl = authManager.currentUser?.photoUrl
                        let instagramUrl = authManager.currentUser?.instagramUrl
                        let linkedinUrl = authManager.currentUser?.linkedinUrl
                        let country = authManager.currentUser?.country
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                    .foregroundColor(.primaryDark)
                                    .frame(width: 144, height: 144)
                                
                                AsyncImageView(
                                    imageUrl: photoUrl,
                                    placeholderText: userName,
                                    contentMode: .fill,
                                    size: 140
                                )
                                .clipShape(Circle())
                            }
                            .shadow(color: .primaryDark.opacity(0.15), radius: 12, x: 0, y: 4)
                            
                            VStack(spacing: 4) {
                                Text(userName)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.primaryDark)
                                
                                if let country = country, !country.isEmpty {
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
                                }
                                
                                HStack(spacing: 10) {
                                    if let linkedinUrl = linkedinUrl, !linkedinUrl.isEmpty {
                                        SocialButton(imageName: "LinkedInLogo", url: linkedinUrl)
                                    }
                                    if let instagramUrl = instagramUrl, !instagramUrl.isEmpty {
                                        SocialButton(imageName: "InstagramLogo", url: instagramUrl)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        
                        ProfileProgressView(user: authManager.currentUser) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                showEditProfile = true
                            }
                        }
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 20) {
                        let areas = authManager.currentUser?.areas ?? []
                        if !areas.isEmpty {
                            ProfileTagsRow(icon: "sparkles", prefix: "I'm passionate about", items: areas)
                        }
                        
                        let interests = authManager.currentUser?.interests ?? []
                        if !interests.isEmpty {
                            ProfileTagsRow(icon: "heart.fill", prefix: "I love", items: interests)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                        VStack(spacing: 16) {
                            Button(action: {
                                showSignOutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "arrow.right.square")
                                        .font(.system(size: 16))
                                    Text("Sign Out")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color("DeepSpace"))
                            .cornerRadius(10)
                            }
                            
                            Button(action: {
                                showDeleteAccountAlert = true
                            }) {
                                Text("Delete Account")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.primaryDark.opacity(0.6))
                                    .underline()
                            }
                            
                            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                Text("Version \(version)")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.primaryDark.opacity(0.4))
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 50)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            showEditProfile = true
                        }
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primaryDark)
                    }
                    .scaleEffect(showEditProfile ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showEditProfile)
                }
            }
            .navigationDestination(isPresented: $showEditProfile) {
                EditProfileView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            viewModel.authenticationManager = authManager
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("If you sign out, you'll need to log in again to access your account.")
        }
        .sheet(isPresented: $showDeleteAccountAlert) {
            DeleteAccountSheetView(
                onDelete: {
                    showDeleteAccountAlert = false
                    Task {
                        await viewModel.deleteAccount()
                    }
                },
                onCancel: {
                    showDeleteAccountAlert = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .overlay {
            if viewModel.isLoading {
                LoaderView()
            }
        }
    }
    
    private var userName: String {
        authManager.currentUser?.name ?? authManager.userName ?? "User"
    }
    
    
}

struct ProfileProgressView: View {
    let user: User?
    let onTap: () -> Void
    
    private var missingItems: [String] {
        var missing: [String] = []
        
        let hasPhoto = user?.photoUrl != nil && !(user?.photoUrl?.isEmpty ?? true)
        if !hasPhoto {
            missing.append("profile photo")
        }
        
        let hasArea = !(user?.areas?.isEmpty ?? true)
        if !hasArea {
            missing.append("expertise area")
        }
        
        let hasCountry = user?.country != nil && !(user?.country?.isEmpty ?? true)
        if !hasCountry {
            missing.append("country")
        }
        
        let hasInterests = !(user?.interests?.isEmpty ?? true)
        if !hasInterests {
            missing.append("interests")
        }
        
        return missing
    }
    
    private var isComplete: Bool {
        missingItems.isEmpty
    }
    
    var body: some View {
        if !isComplete {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                            let completedCount = 4 - missingItems.count
                        let percentage = (completedCount * 100) / 4
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.primaryDark.opacity(0.1))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color("DeepSpace"),
                                            Color("DeepSpace").opacity(0.8)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(percentage) / 100, height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(Color("DeepSpace"))
                        
                        if missingItems.count == 1 {
                            Text("Add your \(missingItems[0])")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.7))
                        } else {
                            Text("Complete your profile: \(missingItems.joined(separator: ", "))")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.7))
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color("DeepSpace").opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("DeepSpace").opacity(0.15), lineWidth: 1.5)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color("DeepSpace"))
                
                Text("Your profile is complete!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("DeepSpace").opacity(0.1), lineWidth: 1)
                    )
            )
        }
    }
}

struct DeleteAccountSheetView: View {
    let onDelete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            Color(.ghostWhite)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        Text("Delete Account")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(Color("DeepSpace"))
                            .padding(.top, 20)
                        
                        Image("MemoMeScared")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            DeleteAccountPoint(
                                icon: "exclamationmark.triangle.fill",
                                text: "This action cannot be undone"
                            )
                            
                            DeleteAccountPoint(
                                icon: "person.2.fill",
                                text: "Your contact information will be removed from all spaces"
                            )
                            
                            DeleteAccountPoint(
                                icon: "rectangle.stack.fill",
                                text: "You will lose all your spaces"
                            )
                            
                            DeleteAccountPoint(
                                icon: "person.fill",
                                text: "You will lose all your contacts"
                            )
                            
                            DeleteAccountPoint(
                                icon: "note.text",
                                text: "You will lose all your notes"
                            )
                        }
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 4) {
                            Text("But if you decide to do it, we'll miss you very much.")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.7))
                                .multilineTextAlignment(.center)
                            
                            Text("We hope to see you soon!")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primaryDark.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                        .padding(.bottom, 20)
                    }
                }
                
                VStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color("DeepSpace"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: onDelete) {
                        Text("Delete Account")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primaryDark.opacity(0.6))
                            .underline()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 34)
                .background(Color(.ghostWhite))
            }
        }
    }
}

struct DeleteAccountPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primaryDark)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(.primaryDark)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct SocialButton: View {
    let imageName: String
    let url: String
    
    private let socialMediaService = SocialMediaService.shared
    
    var body: some View {
        Button(action: {
            if imageName.lowercased().contains("instagram") {
                socialMediaService.openInstagram(urlString: url)
            } else if imageName.lowercased().contains("linkedin") {
                socialMediaService.openLinkedIn(urlString: url)
            } else {
                if let urlObj = URL(string: url) {
                    UIApplication.shared.open(urlObj)
                }
            }
        }) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding(10)
                .background(Color.white.opacity(0.3))
                .clipShape(Circle())
                .shadow(color: .primaryDark.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let prefix: String
    let value: String
    var url: String?
    
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
                
                if let url = url {
                    Link(value, destination: URL(string: url)!)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color("DeepSpace"))
                        .underline()
                } else {
                    Text(value)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.primaryDark)
                }
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

struct ProfileTagsRow: View {
    let icon: String
    let prefix: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("DeepSpace").opacity(0.7))
                    .frame(width: 24, height: 24)
                
                Text(prefix)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(.primaryDark.opacity(0.6))
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
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
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
