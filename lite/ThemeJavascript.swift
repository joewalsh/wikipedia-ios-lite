import WebKit

struct ThemeJavaScript {
    static func set(theme: Theme) -> String {
        return "pagelib.c1.PageMods.setTheme(document, pagelib.c1.Themes.\(theme.kind.jsName))"
    }

    static func dimImages(_ dim: Bool) -> String {
        return "pagelib.c1.PageMods.setDimImages(document, \(dim))"
    }
}
