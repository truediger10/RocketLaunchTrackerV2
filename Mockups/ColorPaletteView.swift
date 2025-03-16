import SwiftUI

struct ColorPaletteView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Rocket Launch Tracker Palette")
                .font(.title)
                .foregroundColor(Color.white)
            
            Group {
                Text("Background Colors")
                    .font(.headline)
                    .foregroundColor(Color.white)
                HStack(spacing: 10) {
                    VStack {
                        Rectangle().fill(Color.black).frame(width: 80, height: 40)
                        Text("baseBackground: #000000")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color(hex: "#0A0A0A")).frame(width: 80, height: 40)
                        Text("deepBackground: #0A0A0A")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color(hex: "#1A1A1A").opacity(0.85)).frame(width: 80, height: 40)
                        Text("cardSurface: #1A1A1A (0.85)")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color(hex: "#212121").opacity(0.9)).frame(width: 80, height: 40)
                        Text("elevatedSurface: #212121 (0.9)")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color(hex: "#3A3A3A").opacity(0.2)).frame(width: 80, height: 40)
                        Text("divider: #3A3A3A (0.2)")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Group {
                Text("Text Colors")
                    .font(.headline)
                    .foregroundColor(Color.white)
                HStack(spacing: 10) {
                    VStack {
                        Rectangle().fill(Color.white).frame(width: 80, height: 40)
                        Text("textPrimary: #FFFFFF")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color(hex: "#A0A0A0")).frame(width: 80, height: 40)
                        Text("textSecondary: #A0A0A0")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color(hex: "#777777")).frame(width: 80, height: 40)
                        Text("textTertiary: #777777")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color(hex: "#505050")).frame(width: 80, height: 40)
                        Text("textDisabled: #505050")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Group {
                Text("Accent Colors")
                    .font(.headline)
                    .foregroundColor(Color.white)
                HStack(spacing: 10) {
                    VStack {
                        Rectangle().fill(Color(hex: "#00AEEF")).frame(width: 80, height: 40)
                        Text("highlightAccent: #00AEEF")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color(hex: "#D7FF00")).frame(width: 80, height: 40)
                        Text("supportAccent: #D7FF00")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color.clear).frame(width: 80, height: 40)
                        Text("tertiaryAccent: Clear")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Group {
                Text("Status Colors")
                    .font(.headline)
                    .foregroundColor(Color.white)
                HStack(spacing: 10) {
                    VStack {
                        Rectangle().fill(Color(hex: "#00AEEF").opacity(0.9)).frame(width: 80, height: 40)
                        Text("statusSuccess: #00AEEF (0.9)")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color.clear).frame(width: 80, height: 40)
                        Text("statusWarning: Clear")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color.clear).frame(width: 80, height: 40)
                        Text("statusError: Clear")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Group {
                Text("Glassmorphic Effects")
                    .font(.headline)
                    .foregroundColor(Color.white)
                HStack(spacing: 10) {
                    VStack {
                        Rectangle().fill(Color.white.opacity(0.05)).frame(width: 80, height: 40)
                        Text("glassEffect: #FFFFFF (0.05)")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color.white.opacity(0.1)).frame(width: 80, height: 40)
                        Text("glassHighlight: #FFFFFF (0.1)")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                    VStack {
                        Rectangle().fill(Color.black.opacity(0.3)).frame(width: 80, height: 40)
                        Text("glassShadow: #000000 (0.3)")
                            .font(.caption)
                            .foregroundColor(Color.white)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ColorPaletteView()
}
