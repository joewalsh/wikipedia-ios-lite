import WebKit

struct ThemeJavaScript {
    static func set(theme: Theme) -> String {
        return "pagelib.c1.PageMods.setTheme(document, pagelib.c1.Themes.\(theme.kind.jsName))"
    }

    static func dimImages(_ dim: Bool) -> String {
        return "pagelib.c1.PageMods.setDimImages(document, \(dim))"
    }
}

struct FooterJavaScript {
    static func updateReadMoreSaveButton(for articleTitle: String, saved: Bool) -> String {
        let buttonTitle = saved ? "Saved for later" : "Save for later"
        return "pagelib.c1.Footer.updateReadMoreSaveButtonForTitle(document, '\(articleTitle)', '\(buttonTitle)', \(saved))"
    }
}

struct ScrollJavaScript {
    static func rectY(for fragment: String) -> String {
        let js =
        """
        const rectY = (fragment) => {
            const el = document.getElementById('\(fragment)')
            const rect = el.getBoundingClientRect()
            return { rectY: rect.top }
        }
        rectY('\(fragment)')
        """
        return js
    }
}
