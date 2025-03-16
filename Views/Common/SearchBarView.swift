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
    var placeholder: String = "Search"
    var onSearch: (() -> Void)? = nil
    
    @FocusState private var fieldIsFocused: Bool
    @State private var isEditing = false
    @State private var showsClearButton = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Styles.inputBackground)
                .overlay(
                    Capsule()
                        .stroke(Styles.glassHighlight, lineWidth: Styles.hairlineBorder)
                )
                .frame(height: Styles.inputHeight)
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isExpanded ? Styles.primaryAccent : Styles.textTertiary)
                    .font(.system(size: Styles.iconSizeSmall))
                    .padding(.leading, Styles.paddingStandard)
                
                if isExpanded {
                    ZStack(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(Styles.textTertiary)
                                .font(Styles.bodyFont)
                        }
                        TextField("", text: $text)
                            .focused($fieldIsFocused)
                            .font(Styles.bodyFont)
                            .foregroundColor(Styles.textPrimary)
                            .padding(.vertical, Styles.paddingMedium)
                            .onChange(of: text) { _, newValue in
                                withAnimation(Styles.easeOut) {
                                    showsClearButton = !newValue.isEmpty
                                }
                            }
                            .onSubmit {
                                if let onSubmit = onSearch {
                                    onSubmit()
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                            }
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
                } else {
                    Text(placeholder)
                        .foregroundColor(Styles.textTertiary)
                        .font(Styles.bodyFont)
                        .padding(.leading, Styles.paddingTiny)
                        .transition(.opacity)
                }
                
                Spacer()
                
                if isExpanded && showsClearButton {
                    Button(action: {
                        withAnimation(Styles.spring) {
                            text = ""
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
                    .padding(.trailing, Styles.paddingSmall)
                }
                
                Button(action: {
                    withAnimation(Styles.spring) {
                        isExpanded.toggle()
                        fieldIsFocused = isExpanded
                        if !isExpanded {
                            text = ""
                        }
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }) {
                    Image(systemName: "chevron.right.2")
                        .foregroundColor(Styles.textSecondary)
                        .font(.system(size: Styles.fontSmall, weight: Styles.weightSemibold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .frame(width: Styles.buttonHeight * 0.75, height: Styles.buttonHeight * 0.75)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, Styles.paddingSmall)
            }
        }
        .animation(Styles.easeInOut, value: isExpanded)
        .animation(Styles.easeOut, value: showsClearButton)
        .animation(Styles.easeOut, value: text)
    }
}

struct SearchBarView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Styles.spaceBackgroundGradient.edgesIgnoringSafeArea(.all)
            VStack(spacing: Styles.spacingLarge) {
                SearchBarView(text: .constant(""), isExpanded: .constant(false))
                    .padding(.horizontal, Styles.paddingStandard)
                SearchBarView(text: .constant("Rocket Launch"), isExpanded: .constant(true))
                    .padding(.horizontal, Styles.paddingStandard)
            }
            .padding(.top, 50)
        }
        .preferredColorScheme(.dark)
    }
}
