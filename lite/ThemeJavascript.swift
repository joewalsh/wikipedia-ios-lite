import WebKit

struct ThemeJavascript {
    static func set(theme: Theme) -> String {
        return "pagelib.c1.PageMods.setTheme(document, pagelib.c1.Themes.\(theme.kind.jsName))"
    }
}
