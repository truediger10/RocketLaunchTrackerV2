//
//  AboutView.swift
//  RocketLaunchTrackerV2
//
//  Created by Troy Ruediger on 3/1/25.
//


import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                aboutSection(title: "RocketLaunchTrackerV1.0", content: "A sample skeleton for the About screen.")
                aboutSection(title: "Credits", content: ["Built by Troy and lots of AI 🤖", "Data from SpaceDevs"])
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func aboutSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
    }

    private func aboutSection(title: String, content: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            ForEach(content, id: \.self) { item in
                Text(item)
                    .font(.body)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.black.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .preferredColorScheme(.dark)
    }
}
