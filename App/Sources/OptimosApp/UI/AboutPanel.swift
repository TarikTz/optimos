import AppKit

/// The standard macOS About panel with our slogan and the credits for the tools OptimosApp uses.
@MainActor
enum AboutPanel {
    static func show() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "OptimosApp",
            .credits: credits(),
        ])
    }

    static func credits() -> NSAttributedString {
        let font = NSFont.systemFont(ofSize: 11)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let text = NSMutableAttributedString(
            string: """
                Capture. Optimize. Convert.

                By Tarik Omercehajic. Released under the MIT License.

                Image optimization is done with these open-source tools, each under its own license:
                """,
            attributes: [.font: font, .paragraphStyle: paragraph, .foregroundColor: NSColor.labelColor])
        let tools: [(String, String, String)] = [
            ("oxipng", "MIT", "https://github.com/shssoichiro/oxipng"),
            ("pngquant", "GPL-3.0-or-later", "https://pngquant.org"),
            ("libjpeg (jpegtran)", "IJG / BSD", "https://libjpeg-turbo.org"),
            ("libwebp", "BSD-3-Clause", "https://developers.google.com/speed/webp"),
        ]
        for (name, license, link) in tools {
            text.append(NSAttributedString(
                string: "\n\(name) — \(license)",
                attributes: [.font: font, .paragraphStyle: paragraph, .link: URL(string: link)!]))
        }
        return text
    }
}
