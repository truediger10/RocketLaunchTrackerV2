//
//  ParallaxEffect.swift
//  RocketLaunchTrackerV2
//
//  Created by Troy Ruediger on 3/2/25.
//


import SwiftUI

struct ParallaxEffect: ViewModifier {
    let magnitude: CGFloat
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: offsetX, y: offsetY)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    offsetY = magnitude * 0.5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(Animation.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
                        offsetX = magnitude * 0.3
                    }
                }
            }
    }
}

struct DeviceMotionParallaxEffect: ViewModifier {
    let magnitude: CGFloat
    
    @State private var offsetX: CGFloat = 0
    @State private var offsetY: CGFloat = 0

    func body(content: Content) -> some View {
        content.offset(x: offsetX, y: offsetY)
    }
}

extension View {
    func parallaxEffect(magnitude: CGFloat = 10) -> some View {
        self.modifier(ParallaxEffect(magnitude: magnitude))
    }
}
