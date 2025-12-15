//
//  CustomPicker.swift
//  Memo Me
//
//  Created by Marian Lisette Hernandez Guzman on 03/12/25.
//

import SwiftUI

extension View {
    @ViewBuilder
    func customPicker(_ config: Binding<PickerConfig>, items: [String]) -> some View {
        self
            .overlay {
                if config.wrappedValue.show {
                    CustomPickerView(texts: items, config: config)
                        .transition(.identity)
                }
            }
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
    @Binding var config: PickerConfig
    @State private var activeText: String?
    @State private var showContents: Bool = false
    @State private var showScrollView: Bool = false
    @State private var expandItems: Bool = false
    
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
            
            // Texto oculto para la animación - no visible para el usuario
            Text(config.text)
                .fontWeight(showContents ? .semibold : .regular)
                .foregroundStyle(.blue)
                .frame(height: 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: showContents ? .trailing : .topLeading)
                .offset(offset)
                .opacity(0) // Siempre invisible
                .ignoresSafeArea(.all, edges: showContents ? [] : .all)
            
            CloseButton()
        }
        .task {
            guard activeText == nil else { return }
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
            if let newValue {
                config.text = newValue
            }
        }
    }
    
    @ViewBuilder
    func CloseButton() -> some View {
        Button {
            Task {
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
            }
        } label: {
            Image(systemName: "xmark")
                .font(.title2)
                .foregroundStyle(Color.primary)
                .frame(width: 45, height: 45)
                .contentShape(.rect)
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
            
            Text(text)
                .fontWeight(.semibold)
                .foregroundStyle(config.text == text ? .blue : .gray)
                .blur(radius: expandItems ? 0 : config.text == text ? 0 : 5)
                .offset(y: offset(proxy))
                .clipped()
                .offset(x: -width * 0.3)
                .rotationEffect(.init(degrees: expandItems ? -rotation(proxy, size) : .zero), anchor: .topTrailing)
                .opacity(opacity(proxy, size))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        .frame(height: 20)
        .lineLimit(1)
        .zIndex(config.text == text ? 1000 : 0)
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

