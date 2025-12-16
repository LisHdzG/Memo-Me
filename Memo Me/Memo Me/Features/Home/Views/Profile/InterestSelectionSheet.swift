//
//  InterestSelectionSheet.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 13/12/25.
//

import SwiftUI

struct InterestSelectionSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""
    
    var filteredCategories: [ProfileViewModel.InterestCategory] {
        if searchText.isEmpty {
            return viewModel.interestCategories
        }
        
        let lowercasedSearch = searchText.lowercased()
        
        return viewModel.interestCategories.compactMap { category in
            let categoryMatches = category.name.lowercased().contains(lowercasedSearch)
            
            let matchingInterests = category.interests.filter { interest in
                interest.lowercased().contains(lowercasedSearch)
            }
            
            if categoryMatches || !matchingInterests.isEmpty {
                if categoryMatches {
                    return ProfileViewModel.InterestCategory(
                        name: category.name,
                        interests: category.interests
                    )
                } else {
                    return ProfileViewModel.InterestCategory(
                        name: category.name,
                        interests: matchingInterests
                    )
                }
            }
            
            return nil
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.ghostWhite)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.primaryDark.opacity(0.6))
                            .padding(.leading, 16)
                        
                        TextField("Search by category or interest...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.primaryDark)
                            .font(.system(size: 16))
                    }
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(filteredCategories, id: \.name) { category in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(category.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.primaryDark)
                                        .padding(.horizontal, 20)
                                    
                                    FlowLayout(spacing: 8) {
                                        ForEach(category.interests, id: \.self) { interest in
                                            InterestCapsule(
                                                interest: interest,
                                                isSelected: viewModel.isInterestSelected(interest),
                                                onTap: {
                                                    viewModel.toggleInterest(interest)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            if filteredCategories.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(.primaryDark.opacity(0.3))
                                    
                                    Text("No interests found")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primaryDark.opacity(0.6))
                                }
                                .padding(.top, 60)
                            }
                            
                            Spacer()
                                .frame(height: 40)
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Select Interests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select Interests")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color("DeepSpace"))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color("RoyalPurple"))
                }
            }
        }
    }
}

struct InterestCapsule: View {
    let interest: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(interest)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isSelected ? .white : .primaryDark)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected 
                    ? Color("RoyalPurple") 
                    : Color.white.opacity(0.3)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected 
                            ? Color("RoyalPurple") 
                            : Color.primaryDark.opacity(0.2),
                            lineWidth: isSelected ? 0 : 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    InterestSelectionSheet(viewModel: ProfileViewModel())
}
