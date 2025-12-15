//
//  CustomPicker.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func customPicker(_ config: Binding<PickerConfig>, items: [String], addNotInList: Bool = false, notInListText: String? = nil) -> some View {
        self
            .overlay {
                if config.wrappedValue.show {
                    let preferNotToSay = "Prefer not to say"
                    let notInListOption = addNotInList ? (notInListText ?? "Not yet in the list") : nil
                    let itemsWithOptions = buildItemsList(items: items, preferNotToSay: preferNotToSay, addNotInList: addNotInList, notInListText: notInListOption)
                    
                    CustomPickerView(texts: itemsWithOptions, originalItems: items, config: config)
                        .transition(.identity)
                }
            }
    }
    
    private func buildItemsList(items: [String], preferNotToSay: String, addNotInList: Bool, notInListText: String?) -> [String] {
        var result = [preferNotToSay]
        result.append(contentsOf: items)
        if addNotInList, let notInListText = notInListText {
            result.append(notInListText)
        }
        return result
    }
}

struct SourcePickerView: View {
    @Binding var config: PickerConfig
    var body: some View {
        Text(config.text)
            .foregroundStyle(.blue)
            .frame(height: 20)
            .opacity(config.show ? 0 : 1)
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { newValue in
                config.sourceFrame = newValue
            }
    }
}

struct PickerConfig {
    var text: String
    init(text: String) {
        self.text = text
    }
    
    var show: Bool = false
    var sourceFrame: CGRect = .zero
}

fileprivate struct CustomPickerView: View {
    var texts: [String]
    var originalItems: [String]
    @Binding var config: PickerConfig
    @State private var activeText: String?
    @State private var showContents: Bool = false
    @State private var showScrollView: Bool = false
    @State private var expandItems: Bool = false
    @State private var hasScrolled: Bool = false
    @State private var initialText: String?
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(showContents ? 1 : 0)
                .ignoresSafeArea()
            
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(texts, id: \.self) { text in
                        CardView(text, size: size)
                    }
                }
                .scrollTargetLayout()
            }
            .safeAreaPadding(.top, (size.height * 0.5) - 20)
            .safeAreaPadding(.bottom, (size.height * 0.5))
            .scrollPosition(id: $activeText, anchor: .center)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollIndicators(.hidden)
            .opacity(showScrollView ? 1 : 0)
            .allowsHitTesting(expandItems && showScrollView)
            
            let offset: CGSize = .init(
                width: showContents ? size.width * -0.3 : config.sourceFrame.minX,
                height: showContents ? -10 : config.sourceFrame.minY
            )
            
            Text(config.text)
                .fontWeight(showContents ? .semibold : .regular)
                .foregroundStyle(.blue)
                .frame(height: 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: showContents ? .trailing : .topLeading)
                .offset(offset)
                .opacity(0)
                .ignoresSafeArea(.all, edges: showContents ? [] : .all)
            
            CloseButton()
        }
        .task {
            guard activeText == nil else { return }
            initialText = config.text
            if texts.contains(config.text) {
                activeText = config.text
            } else {
                activeText = texts.first
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                showContents = true
            }
            
            try? await Task.sleep(for: .seconds(0.3))
            showScrollView = true
            
            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                expandItems = true
            }
        }
        .onChange(of: activeText) { oldValue, newValue in
            if let newValue, let oldValue = oldValue, oldValue != newValue {
                hasScrolled = true
            }
        }
    }
    
    @ViewBuilder
    func CloseButton() -> some View {
        Button {
            Task {
                if hasScrolled {
                    if let selectedText = activeText {
                        let preferNotToSay = "Prefer not to say"
                        let notInList = "Not yet in the list"
                        let notInListValue = "Not yet in the list"
                        
                        if selectedText == preferNotToSay {
                            if let initial = initialText {
                                if initial.contains("country") || initial.contains("país") {
                                    config.text = "Select your country"
                                } else if initial.contains("interests") || initial.contains("intereses") {
                                    config.text = "Select your professional interests"
                                } else {
                                    if config.text.contains("country") || config.text.contains("país") {
                                        config.text = "Select your country"
                                    } else if config.text.contains("interests") || config.text.contains("intereses") {
                                        config.text = "Select your professional interests"
                                    } else {
                                        config.text = "Select your country"
                                    }
                                }
                            } else {
                                if config.text.contains("country") || config.text.contains("país") {
                                    config.text = "Select your country"
                                } else if config.text.contains("interests") || config.text.contains("intereses") {
                                    config.text = "Select your professional interests"
                                } else {
                                    config.text = "Select your country"
                                }
                            }
                        } else if selectedText == notInList {
                            config.text = notInListValue
                        } else {
                            config.text = selectedText
                        }
                    }
                }
                
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandItems = false
                }
                
                try? await Task.sleep(for: .seconds(0.2))
                showScrollView = false
                withAnimation(.easeInOut(duration: 0.2)) {
                    showContents = false
                }
                
                try? await Task.sleep(for: .seconds(0.2))
                
                config.show = false
                activeText = nil
                hasScrolled = false
                initialText = nil
            }
        } label: {
            ZStack {
                Circle()
                    .fill(hasScrolled ? Color(.deepSpace) : Color.gray.opacity(0.3))
                    .frame(width: 45, height: 45)
                
                Image(systemName: hasScrolled ? "checkmark" : "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(hasScrolled ? .white : .gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .offset(x: showContents ? -50 : -20, y: -10)
        .opacity(showContents ? 1 : 0)
        .blur(radius: showContents ? 0 : 5)
    }
    
    @ViewBuilder
    private func CardView(_ text: String, size: CGSize) -> some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let isActive = activeText == text
            
            Text(text)
                .fontWeight(.semibold)
                .foregroundStyle(isActive ? Color(.deepSpace) : .gray)
                .blur(radius: expandItems ? 0 : isActive ? 0 : 5)
                .offset(y: offset(proxy))
                .clipped()
                .offset(x: -width * 0.3)
                .rotationEffect(.init(degrees: expandItems ? -rotation(proxy, size) : .zero), anchor: .topTrailing)
                .opacity(opacity(proxy, size))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        .frame(height: 20)
        .lineLimit(1)
        .zIndex(activeText == text ? 1000 : 0)
    }
    
    private func offset(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        return expandItems ? 0 : -minY
    }
    
    private func rotation(_ proxy: GeometryProxy, _ size: CGSize) -> CGFloat {
        let height = size.height * 0.5
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let maxRotation: CGFloat = 220
        let progress = minY / height
        
        return progress * maxRotation
    }
    
    private func opacity(_ proxy: GeometryProxy, _ size: CGSize) -> CGFloat {
        let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
        let height = size.height * 0.5
        let progress = (minY / height) * 2.8
        let opacity = progress < 0 ? 1 + progress : 1 - progress
        
        return opacity
    }
}

