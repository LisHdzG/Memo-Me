//
//  ProfileViewModel.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI
import PhotosUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profileImage: UIImage?
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var name: String = ""
    @Published var country: String?
    @Published var primaryExpertiseArea: String?
    @Published var secondaryExpertiseArea: String?
    @Published var selectedInterests: [String] = []
    @Published var instagramUrl: String = ""
    @Published var linkedinUrl: String = ""
    
    @Published var countryConfig: PickerConfig = .init(text: "Select your country")
    @Published var primaryExpertiseConfig: PickerConfig = .init(text: "Select your professional interests")
    @Published var secondaryExpertiseConfig: PickerConfig = .init(text: "Select your professional interests")
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isDataLoaded: Bool = false
    @Published var showInterestsSheet: Bool = false
    
    private var originalName: String = ""
    private var originalCountry: String?
    private var originalPrimaryExpertiseArea: String?
    private var originalSecondaryExpertiseArea: String?
    private var originalInterests: [String] = []
    private var originalPhotoUrl: String?
    private var originalInstagramUsername: String = ""
    private var originalLinkedinUsername: String = ""
    
    private let userService = UserService()
    private let profileImageService = ProfileImageService.shared
    private let selectionListsService = SelectionListsService.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    var authenticationManager: AuthenticationManager?
    
    var hasChanges: Bool {
        let nameChanged = name.trimmingCharacters(in: .whitespacesAndNewlines) != originalName.trimmingCharacters(in: .whitespacesAndNewlines)
        let countryChanged = country != originalCountry
        let primaryAreaChanged = primaryExpertiseArea != originalPrimaryExpertiseArea
        let secondaryAreaChanged = secondaryExpertiseArea != originalSecondaryExpertiseArea
        let interestsChanged = Set(selectedInterests) != Set(originalInterests)
        let photoChanged = selectedPhotoItem != nil || (profileImage == nil && originalPhotoUrl != nil)
        let instagramChanged = instagramUrl.trimmingCharacters(in: .whitespacesAndNewlines) != originalInstagramUsername
        let linkedinChanged = linkedinUrl.trimmingCharacters(in: .whitespacesAndNewlines) != originalLinkedinUsername
        
        return nameChanged || countryChanged || primaryAreaChanged || secondaryAreaChanged || interestsChanged || photoChanged || instagramChanged || linkedinChanged
    }
    
    var countries: [String] {
        selectionListsService.countries
    }
    
    var notInListCountry: String {
        selectionListsService.notInListCountry
    }
    
    var expertiseAreas: [String] {
        selectionListsService.expertiseAreas
    }
    
    struct InterestCategory {
        let name: String
        let interests: [String]
    }
    
    let interestCategories: [InterestCategory] = [
        InterestCategory(name: "Art & Culture", interests: [
            "Architecture", "Art History", "Calligraphy", "Ceramics", "Classical Music",
            "Contemporary Art", "Dance", "Digital Art", "Drawing", "Fashion Design",
            "Film Making", "Jazz", "Literature", "Museums", "Opera",
            "Painting", "Photography", "Poetry", "Sculpture", "Street Art",
            "Theater", "Writing"
        ]),
        InterestCategory(name: "Books & Reading", interests: [
            "Biographies", "Classic Literature", "Comic Books", "Fantasy Novels",
            "Historical Fiction", "Manga", "Mystery Novels", "Non-Fiction",
            "Poetry", "Science Fiction", "Self-Help", "Thriller Novels"
        ]),
        InterestCategory(name: "Business & Entrepreneurship", interests: [
            "Business Strategy", "Entrepreneurship", "Finance", "Investing",
            "Marketing", "Networking", "Real Estate", "Startups"
        ]),
        InterestCategory(name: "Cooking & Food", interests: [
            "Asian Cuisine", "Baking", "Barbecue", "Coffee", "Craft Beer",
            "French Cuisine", "Italian Cuisine", "Meal Prep", "Pastry",
            "Plant-Based Cooking", "Wine Tasting"
        ]),
        InterestCategory(name: "Education & Learning", interests: [
            "Astronomy", "Biology", "Chemistry", "Economics", "History",
            "Languages", "Mathematics", "Philosophy", "Physics", "Psychology"
        ]),
        InterestCategory(name: "Entertainment", interests: [
            "Anime", "Broadway Shows", "Documentaries", "Movies", "Music Festivals",
            "Podcasts", "Stand-up Comedy", "TV Shows", "Video Games"
        ]),
        InterestCategory(name: "Fitness & Sports", interests: [
            "Basketball", "Cycling", "Fitness", "Golf", "Hiking",
            "Martial Arts", "Meditation", "Running", "Soccer", "Swimming",
            "Tennis", "Weightlifting", "Yoga"
        ]),
        InterestCategory(name: "Gaming", interests: [
            "Board Games", "Card Games", "Console Gaming", "Mobile Gaming",
            "PC Gaming", "Puzzle Games", "Strategy Games", "VR Gaming"
        ]),
        InterestCategory(name: "Health & Wellness", interests: [
            "Meditation", "Mental Health", "Nutrition", "Sleep Health",
            "Stress Management", "Wellness", "Yoga"
        ]),
        InterestCategory(name: "Hobbies & Crafts", interests: [
            "Calligraphy", "DIY Projects", "Gardening", "Knitting",
            "Origami", "Pottery", "Sewing", "Woodworking"
        ]),
        InterestCategory(name: "Music", interests: [
            "Classical Music", "Country Music", "Electronic Music", "Hip-Hop",
            "Indie Music", "Jazz", "K-Pop", "Pop Music", "Rock Music",
            "Live Music", "Songwriting", "Playing Guitar"
        ]),
        InterestCategory(name: "Pets & Animals", interests: [
            "Dogs", "Cats", "Pet Training", "Animal Rescue", "Exotic Pets",
            "Bird Watching", "Aquarium Keeping"
        ]),
        InterestCategory(name: "Nature & Outdoor", interests: [
            "Astronomy", "Bird Watching", "Camping", "Hiking",
            "Nature Photography", "Wildlife", "Outdoor Adventures"
        ]),
        InterestCategory(name: "Science & Technology", interests: [
            "AI & Machine Learning", "Astronomy", "Biology", "Coding",
            "Engineering", "Robotics", "Space Exploration", "Technology"
        ]),
        InterestCategory(name: "Series & TV", interests: [
            "Anime Series", "Comedy Series", "Crime Series", "Drama Series",
            "Documentary Series", "Fantasy Series", "Reality TV", "Sci-Fi Series",
            "Thriller Series"
        ]),
        InterestCategory(name: "Social & Community", interests: [
            "Activism", "Charity Work", "Community Service", "Networking",
            "Social Causes", "Volunteering"
        ]),
        InterestCategory(name: "Travel", interests: [
            "Adventure Travel", "Backpacking", "Beach Travel", "City Breaks",
            "Cultural Tourism", "Ecotourism", "Food Tourism", "Solo Travel",
            "Road Trips", "Digital Nomad Life"
        ])
    ]
    
    init() {
        setupPhotoObserver()
    }
    
    func loadUserData() {
        guard let user = authenticationManager?.currentUser else { return }
        
        originalName = user.name
        originalCountry = user.country
        let userAreas = user.areas ?? []
        originalPrimaryExpertiseArea = userAreas.first
        originalSecondaryExpertiseArea = userAreas.count > 1 ? userAreas[1] : nil
        originalInterests = user.interests ?? []
        originalPhotoUrl = user.photoUrl
        
        if let savedInstagramUrl = user.instagramUrl, !savedInstagramUrl.isEmpty {
            originalInstagramUsername = SocialMediaService.shared.extractInstagramUsername(from: savedInstagramUrl) ?? ""
        } else {
            originalInstagramUsername = ""
        }
        
        if let savedLinkedinUrl = user.linkedinUrl, !savedLinkedinUrl.isEmpty {
            originalLinkedinUsername = SocialMediaService.shared.extractLinkedInUsername(from: savedLinkedinUrl) ?? ""
        } else {
            originalLinkedinUsername = ""
        }
        
        name = user.name
        country = user.country
        
        if let country = country {
            countryConfig.text = country
        } else {
            countryConfig.text = "Select your country"
        }
        
        primaryExpertiseArea = userAreas.first
        secondaryExpertiseArea = userAreas.count > 1 ? userAreas[1] : nil
        
        if let primary = primaryExpertiseArea {
            primaryExpertiseConfig.text = primary
        } else {
            primaryExpertiseConfig.text = "Select your professional interests"
        }
        
        if let secondary = secondaryExpertiseArea {
            secondaryExpertiseConfig.text = secondary
        } else {
            secondaryExpertiseConfig.text = "Select your professional interests"
        }
        
        selectedInterests = user.interests ?? []
        
        if let savedInstagramUrl = user.instagramUrl, !savedInstagramUrl.isEmpty {
            self.instagramUrl = SocialMediaService.shared.extractInstagramUsername(from: savedInstagramUrl) ?? ""
        } else {
            self.instagramUrl = ""
        }
        
        if let savedLinkedinUrl = user.linkedinUrl, !savedLinkedinUrl.isEmpty {
            self.linkedinUrl = SocialMediaService.shared.extractLinkedInUsername(from: savedLinkedinUrl) ?? ""
        } else {
            self.linkedinUrl = ""
        }
        
        if let photoUrl = user.photoUrl, let url = URL(string: photoUrl) {
            Task {
                await loadImageFromUrl(url)
            }
        }
        
        selectedPhotoItem = nil
        isDataLoaded = true
    }
    
    private func loadImageFromUrl(_ url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                profileImage = image
            }
        } catch {
        }
    }
    
    private func setupPhotoObserver() {
        $selectedPhotoItem
            .compactMap { $0 }
            .sink { [weak self] item in
                Task { @MainActor in
                    await self?.loadPhoto(from: item)
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadPhoto(from item: PhotosPickerItem) async {
        isLoading = true
        errorMessage = nil
        LoaderPresenter.shared.show()
        
        defer {
            LoaderPresenter.shared.hide()
            isLoading = false
        }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    profileImage = image
                } else {
                    errorMessage = "Could not load image"
                    ErrorPresenter.shared.showServiceError { [weak self] in
                        Task { @MainActor in
                            await self?.loadPhoto(from: item)
                        }
                    }
                }
            } else {
                errorMessage = "Error processing image"
                ErrorPresenter.shared.showServiceError { [weak self] in
                    Task { @MainActor in
                        await self?.loadPhoto(from: item)
                    }
                }
            }
        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            ErrorPresenter.shared.showServiceError { [weak self] in
                Task { @MainActor in
                    await self?.loadPhoto(from: item)
                }
            }
        }
    }
    
    func removePhoto() {
        profileImage = nil
        selectedPhotoItem = nil
    }
    
    func selectCountry(_ country: String) {
        self.country = country
        countryConfig.text = country
    }
    
    func selectPrimaryExpertise(_ expertise: String) {
        if secondaryExpertiseArea == expertise {
            if let oldPrimary = primaryExpertiseArea {
                secondaryExpertiseArea = oldPrimary
                secondaryExpertiseConfig.text = oldPrimary
            } else {
                secondaryExpertiseArea = nil
                secondaryExpertiseConfig.text = "Select your professional interests"
            }
        }
        self.primaryExpertiseArea = expertise
        primaryExpertiseConfig.text = expertise
    }
    
    func selectSecondaryExpertise(_ expertise: String) {
        guard expertise != primaryExpertiseArea else { return }
        self.secondaryExpertiseArea = expertise
        secondaryExpertiseConfig.text = expertise
    }
    
    func clearPrimaryExpertise() {
        primaryExpertiseArea = nil
        primaryExpertiseConfig.text = "Select your professional interests"
    }
    
    func clearSecondaryExpertise() {
        secondaryExpertiseArea = nil
        secondaryExpertiseConfig.text = "Select your professional interests"
    }
    
    func addInterest(_ interest: String) {
        if !selectedInterests.contains(interest) {
            selectedInterests.append(interest)
        }
    }
    
    func removeInterest(_ interest: String) {
        selectedInterests.removeAll { $0 == interest }
    }
    
    func toggleInterest(_ interest: String) {
        if selectedInterests.contains(interest) {
            removeInterest(interest)
        } else {
            addInterest(interest)
        }
    }
    
    func isInterestSelected(_ interest: String) -> Bool {
        selectedInterests.contains(interest)
    }
    
    func saveProfile() async -> Bool {
        guard let currentUser = authenticationManager?.currentUser,
              let userId = currentUser.id,
              let appleId = authenticationManager?.userIdentifier else {
            errorMessage = "Could not retrieve user information"
            return false
        }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Name is required"
            return false
        }
        
        isLoading = true
        LoaderPresenter.shared.show()
        defer {
            LoaderPresenter.shared.hide()
            isLoading = false
        }
        errorMessage = nil
        successMessage = nil
        
        do {
            var photoUrl: String? = currentUser.photoUrl
            if let image = profileImage {
                if selectedPhotoItem != nil {
                    photoUrl = try await profileImageService.uploadProfileImage(
                        image,
                        appleId: appleId,
                        oldPhotoUrl: currentUser.photoUrl
                    )
                }
            } else if selectedPhotoItem == nil && profileImage == nil {
                if let oldPhotoUrl = currentUser.photoUrl {
                    try? await profileImageService.deleteProfileImage(for: appleId, photoUrl: oldPhotoUrl)
                }
                photoUrl = nil
            }
            
            let trimmedInstagramUrl = instagramUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedLinkedinUrl = linkedinUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let formattedInstagramUrl: String? = trimmedInstagramUrl.isEmpty ? nil : SocialMediaService.shared.formatInstagramURL(trimmedInstagramUrl)
            let formattedLinkedinUrl: String? = trimmedLinkedinUrl.isEmpty ? nil : SocialMediaService.shared.formatLinkedInURL(trimmedLinkedinUrl)
            
            var areas: [String] = []
            if let primary = primaryExpertiseArea {
                areas.append(primary)
            }
            if let secondary = secondaryExpertiseArea, secondary != primaryExpertiseArea {
                areas.append(secondary)
            }
            let areasToSave: [String]? = areas.isEmpty ? nil : areas
            
            let updatedUser = User(
                id: userId,
                appleId: appleId,
                name: trimmedName,
                country: country,
                areas: areasToSave,
                interests: selectedInterests.isEmpty ? nil : selectedInterests,
                photoUrl: photoUrl,
                instagramUrl: formattedInstagramUrl,
                linkedinUrl: formattedLinkedinUrl
            )
            
            try await userService.updateUser(updatedUser)
            
            authenticationManager?.updateCachedUser(updatedUser)
            
            originalName = trimmedName
            originalCountry = country
            originalPrimaryExpertiseArea = primaryExpertiseArea
            originalSecondaryExpertiseArea = secondaryExpertiseArea
            originalInterests = selectedInterests
            originalPhotoUrl = photoUrl
            originalInstagramUsername = trimmedInstagramUrl.isEmpty ? "" : (SocialMediaService.shared.extractInstagramUsername(from: trimmedInstagramUrl) ?? "")
            originalLinkedinUsername = trimmedLinkedinUrl.isEmpty ? "" : (SocialMediaService.shared.extractLinkedInUsername(from: trimmedLinkedinUrl) ?? "")
            selectedPhotoItem = nil
            
            successMessage = "Profile updated successfully"
            
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    successMessage = nil
                }
            }
            
            return true
        } catch {
            errorMessage = "Error updating profile: \(error.localizedDescription)"
            ErrorPresenter.shared.showServiceError { [weak self] in
                Task { @MainActor in
                    _ = await self?.saveProfile()
                }
            }
            return false
        }
    }
    
    func deleteAccount() async -> Bool {
        guard let currentUser = authenticationManager?.currentUser,
              let userId = currentUser.id else {
            errorMessage = "Could not retrieve user information"
            return false
        }
        
        isLoading = true
        LoaderPresenter.shared.show()
        defer {
            LoaderPresenter.shared.hide()
            isLoading = false
        }
        errorMessage = nil
        
        do {
            try await userService.deleteUser(userId: userId)
            
            authenticationManager?.signOut(clearLocalData: true)
            
            return true
        } catch {
            errorMessage = "Error deleting account: \(error.localizedDescription)"
            ErrorPresenter.shared.showServiceError { [weak self] in
                Task { @MainActor in
                    _ = await self?.deleteAccount()
                }
            }
            return false
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}
