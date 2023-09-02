//
//  File.swift
//  
//
//  Created by James Pamplona on 8/25/23.
//
#if DEBUG
import SwiftUI


struct Tag: Identifiable {
    let name: String
    let color: Color
    let id = UUID()
}

let tagNames = [
"Tag1", // 0
"Tag2", // 1
"Tag3", // 2
"Tag4", // 3
"Really Quite long tag name", // 4
"PN: 3409573", // 5
"High Rate", // 6
"Office", // 7
"Field", // 8
"Task: Technical Support", // 9
"😸", // 10
]

let shuffledTags = tagNames.shuffled()

let cornerCase1Names = [
//    tagNames[3],
//    tagNames[6],
//    tagNames[10],
//    tagNames[1],
//    tagNames[0],
//    tagNames[5],
//    tagNames[9],
//    tagNames[8],
    tagNames[4],
    tagNames[7],
    tagNames[2],
]

let cornerCase2Names = [
    tagNames[3],
    tagNames[2],
    tagNames[0],
    tagNames[10],
    tagNames[7],
    tagNames[4],
    tagNames[6],
    tagNames[5],
    tagNames[8],
    tagNames[1],
    tagNames[9],
]

struct PreviewData {
    static let tags: [Tag] = shuffledTags.map { Tag(name: $0, color: .rainbow.random()) }
    static let cornerCase1: [Tag] = cornerCase1Names.map { Tag(name: $0, color: .rainbow.random()) }
    static let cornerCase2: [Tag] = cornerCase2Names.map { Tag(name: $0, color: .rainbow.random()) }
}

struct TagView: View {
    let tag: Tag

    var body: some View {
        Text(tag.name)
            .bold()
            .foregroundColor(tag.color.contrastingForegroundColor)
            .padding(.vertical, 7)
            .padding(.horizontal, 12)
            .frame(minWidth: 80, minHeight: 40)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tag.color)
            }
    }
}

extension Color {
    func contrastRatio(with color: Color) -> Double {
        let luminance1 = luminance
        let luminance2 = color.luminance
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)

        return (lighter + 0.05) / (darker + 0.05)
    }

    var contrastingForegroundColor: Color {
        contrastRatio(with: .white) >= 2.2 ? .white : .black
    }

    private var luminance: Double {
        let components = self.components

        /// https://en.wikipedia.org/wiki/Relative_luminance
        let redRelativeLuminance = 0.2126
        let greenRelativeLuminance = 0.7152
        let blueRelativeLuminance = 0.0722

        return (redRelativeLuminance * components.red) + (greenRelativeLuminance * components.green) + (blueRelativeLuminance * components.blue)
    }
}

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Color {
    var components: (red: CGFloat, green: CGFloat, blue: CGFloat, opacity: CGFloat) {

#if canImport(UIKit)
        typealias NativeColor = UIColor
#elseif canImport(AppKit)
        typealias NativeColor = NSColor
#endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var o: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &o) else {
            // You can handle the failure here as you want
            return (0, 0, 0, 0)
        }

        return (r, g, b, o)
    }

    var hex: String {
        String(
            format: "#%02x%02x%02x%02x",
            Int(components.red * 255),
            Int(components.green * 255),
            Int(components.blue * 255),
            Int(components.opacity * 255)
        )
    }
}

@available(iOS 15, macOS 12, *)
extension Color {
    static var rainbow: Rainbow.Type {
        Rainbow.self
    }

    enum Rainbow {
        static var red: Color     = .red
        static var orange: Color  = .orange
        static var yellow: Color  = .yellow
        static var green: Color   = .green
        static var blue: Color    = .blue
        static var indigo: Color  = .indigo
        static var violet: Color  = .purple

        static var allColors: [Color] = [
            .red,
            .orange,
            .yellow,
            .green,
            .blue,
            .indigo,
            .purple,
        ]
        static func random() -> Color {
            allColors.randomElement()!
        }
    }
}
#endif
