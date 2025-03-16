import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    @Binding var isExpanded: Bool {
        didSet {
            if !isExpanded {
                text = ""
            }
        }
    }
    var placeholder: String = "Search launches..."
    var onSearch: (() -> Void)? = nil
    
    @FocusState private var fieldIsFocused: Bool
    @State private var showsClearButton = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main search bar
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Styles.inputBackground)
                    .overlay(
                        Capsule()
                            .stroke(fieldIsFocused ? Styles.primaryAccent.opacity(0.3) : Styles.glassHighlight,
                                   lineWidth: Styles.hairlineBorder)
                    )
                    .frame(height: Styles.inputHeight)
                
                HStack(spacing: Styles.spacingSmall) {
                    // Search icon
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(fieldIsFocused || !text.isEmpty ? Styles.primaryAccent : Styles.textTertiary)
                        .font(.system(size: Styles.iconSizeSmall))
                        .padding(.leading, Styles.paddingStandard)
                    
                    // Text field
                    ZStack(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(Styles.textTertiary)
                                .font(Styles.bodyFont)
                                .animation(.easeOut, value: text.isEmpty)
                        }
                        
                        TextField("", text: $text)
                            .focused($fieldIsFocused)
                            .font(Styles.bodyFont)
                            .foregroundColor(Styles.textPrimary)
                            .padding(.vertical, Styles.paddingSmall)
                            .submitLabel(.search)
                            .onChange(of: text) { _, newValue in
                                withAnimation(Styles.easeOut) {
                                    showsClearButton = !newValue.isEmpty
                                }
                            }
                            .onSubmit {
                                fieldIsFocused = false
                                if let onSubmit = onSearch {
                                    onSubmit()
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            }
                    }
                    
                    Spacer()
                    
                    // Clear button
                    if showsClearButton {
                        Button(action: {
                            withAnimation(Styles.spring) {
                                text = ""
                                fieldIsFocused = true // Keep focus when clearing
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Styles.textTertiary)
                                .font(.system(size: Styles.iconSizeSmall))
                                .frame(width: Styles.iconSizeMedium, height: Styles.iconSizeMedium)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    // Cancel button
                    Button(action: {
                        withAnimation(Styles.spring) {
                            isExpanded = false
                            fieldIsFocused = false
                            text = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Text("Cancel")
                            .font(Styles.buttonFont)
                            .foregroundColor(Styles.primaryAccent)
                            .padding(.trailing, Styles.paddingMedium)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            
            // Optional search suggestions when typing
            if fieldIsFocused && !text.isEmpty {
                suggestionsList
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            // Auto-focus when shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                fieldIsFocused = true
            }
        }
    }
    
    // Search suggestions UI
    private var suggestionsList: some View {
        VStack(alignment: .leading, spacing: Styles.spacingTiny) {
            // Here you could show recent searches, popular searches, etc.
            // This is a placeholder implementation
            ForEach(getSuggestions(), id: \.self) { suggestion in
                Button {
                    text = suggestion
                    fieldIsFocused = false
                    if let onSubmit = onSearch {
                        onSubmit()
                    }
                } label: {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: Styles.fontTiny))
                            .foregroundColor(Styles.textTertiary)
                        
                        Text(suggestion)
                            .font(Styles.bodyFont)
                            .foregroundColor(Styles.textSecondary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: Styles.fontTiny))
                            .foregroundColor(Styles.textTertiary)
                    }
                    .padding(.vertical, Styles.paddingSmall)
                    .padding(.horizontal, Styles.paddingMedium)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Styles.glassHighlight.opacity(0.2))
                    .padding(.horizontal, Styles.paddingMedium)
            }
        }
        .padding(.vertical, Styles.paddingSmall)
        .background(
            RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                .fill(Styles.cardSurface.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: Styles.cornerRadiusMedium)
                        .stroke(Styles.glassHighlight.opacity(0.2), lineWidth: Styles.hairlineBorder)
                )
        )
        .padding(.horizontal, Styles.paddingTiny)
        .padding(.top, Styles.paddingTiny)
    }
    
    // Helper to generate search suggestions based on current input
    private func getSuggestions() -> [String] {
        if text.isEmpty { return [] }
        
        // These could be pulled from a real suggestion service
        let commonTerms = ["SpaceX", "Crew Dragon", "Falcon 9", "Starship", "ISS", "NASA", "Artemis", "Blue Origin", "Rocket Lab"]
        
        return commonTerms
            .filter { $0.lowercased().contains(text.lowercased()) }
            .prefix(3)
            .map { $0 }
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all)
            VStack(spacing: Styles.spacingLarge) {
                SearchBarView(text: .constant(""), isExpanded: .constant(true))
                    .padding(.horizontal, Styles.paddingStandard)
                SearchBarView(text: .constant("Space"), isExpanded: .constant(true))
                    .padding(.horizontal, Styles.paddingStandard)
            }
            .padding(.top, 50)
        }
        .preferredColorScheme(.dark)
    }
}
