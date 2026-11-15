#Requires AutoHotkey v2.0
#SingleInstance Force

;@Ahk2Exe-SetMainIcon latex_L_icon_white.ico
;@Ahk2Exe-SetName LaTeX to Text
;@Ahk2Exe-SetDescription LaTeX to Text
;@Ahk2Exe-SetVersion 1.0.0

A_IconTip := "LaTeX to Text"

; Register this program to start with Windows (only when compiled to .exe)
if A_IsCompiled
    RegWrite '"' A_ScriptFullPath '"', "REG_SZ"
        , "HKCU\Software\Microsoft\Windows\CurrentVersion\Run", "latex_to_text"

CoordMode "Mouse", "Screen"
toastGui := ""
toastAlpha := 230   ; opacity: 255 = solid, lower = more transparent

$+^l:: {
    KeyWait "Shift"
    KeyWait "Ctrl"
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.5) {
        A_Clipboard := saved
        Send "+^l"          ; nothing selected: pass the keystroke through
        return
    }
    A_Clipboard := LatexToText(A_Clipboard)
    ShowToast("Copied!")
}

ShowToast(msg) {
    global toastGui, toastAlpha
    SetTimer HideToast, 0
    if IsObject(toastGui)
        toastGui.Destroy()

    scale := A_ScreenDPI / 96
    padX := Round(10 * scale)    ; space left and right
    padY := Round(3 * scale)     ; space above and below
    th   := Round(18 * scale)    ; text row height

    toastGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")  ; click-through
    toastGui.BackColor := "1E1E2E"
    toastGui.MarginX := 0
    toastGui.MarginY := 0

    toastGui.SetFont("s10 bold cA6E3A1", "Segoe UI")
    t := toastGui.Add("Text", "x" padX " y" padY " h" th " +0x200", msg)
    t.GetPos(, , &mw)            ; real measured text width

    w := padX * 2 + mw
    h := padY * 2 + th
    toastGui.Show("Hide w" w " h" h)
    WinGetPos , , &w, &h, toastGui.Hwnd
    WinSetRegion "0-0 w" w " h" h " R12-12", toastGui.Hwnd

    ; position: always the mouse
    CoordMode "Mouse", "Screen"
    MouseGetPos &px, &py

    yOffset := Round(30 * scale)   ; raise the pop-up this many pixels above the position
    WinSetTransparent 0, toastGui.Hwnd
    toastGui.Show("NA x" (px - w // 2) " y" (py - h // 2 - yOffset))
    Loop 5 {                                        ; fade in
        WinSetTransparent Round(toastAlpha * A_Index / 5), toastGui.Hwnd
        Sleep 15
    }
    SetTimer HideToast, -900
}

HideToast() {
    global toastGui, toastAlpha
    if !IsObject(toastGui)
        return
    Loop 5 {                                        ; fade out
        WinSetTransparent Round(toastAlpha * (5 - A_Index) / 5), toastGui.Hwnd
        Sleep 20
    }
    toastGui.Destroy()
    toastGui := ""
}

LatexToText(s) {
    ; --- delimiters and layout-only commands ---
    s := StrReplace(s, "$", "")
    s := RegExReplace(s, "\\[dt]frac", "\frac")
    s := RegExReplace(s, "\\[dt]binom", "\binom")
    s := RegExReplace(s, "\\(?:left|right)\.", "")
    s := RegExReplace(s, "\\(?:left|right)(?![A-Za-z])\s*", "")
    s := RegExReplace(s, "\\(?:displaystyle|textstyle|scriptstyle|limits|nolimits|[bB]ig{1,2}[lrm]?)(?![A-Za-z])\s*", "")

    ; escaped braces are kept as real braces (restored at the end)
    s := StrReplace(s, "\{", Chr(1))
    s := StrReplace(s, "\}", Chr(2))

    ; degrees
    s := StrReplace(s, "^{\circ}", "°")
    s := RegExReplace(s, "\^\\circ(?![A-Za-z])", "°")

    ; Euler's number and imaginary unit
    s := StrReplace(s, "\mathrm{e}", "ℯ", true)
    s := StrReplace(s, "\text{e}", "ℯ", true)
    s := StrReplace(s, "\mathrm{i}", "ⅈ", true)

    ; number sets
    s := StrReplace(s, "\mathbb{R}", "ℝ", true)
    s := StrReplace(s, "\mathbb{N}", "ℕ", true)
    s := StrReplace(s, "\mathbb{Z}", "ℤ", true)
    s := StrReplace(s, "\mathbb{Q}", "ℚ", true)
    s := StrReplace(s, "\mathbb{C}", "ℂ", true)

    ; commands that only style their content: keep the content
    s := RegExReplace(s, "\\(?:text|textbf|textit|mathrm|mathbf|mathit|mathsf|mathtt|mathcal|boldsymbol|operatorname|vec|hat|bar|overline|underline|overrightarrow|tilde|dot|ddot)\{([^{}]*)\}", "$1")

    ; --- fractions, binomials, roots ---
    while (p := InStr(s, "\frac")) {
        i := p + 5
        a := Group(s, &i)
        b := Group(s, &i)
        s := SubStr(s, 1, p - 1) "((" a ")/(" b "))" SubStr(s, i)
    }

    while (p := InStr(s, "\binom")) {
        i := p + 6
        a := Group(s, &i)
        b := Group(s, &i)
        s := SubStr(s, 1, p - 1) "nCr(" a "," b ")" SubStr(s, i)
    }

    while (p := InStr(s, "\sqrt")) {
        i := p + 5
        n := ""
        if (SubStr(s, i, 1) = "[") {
            close := InStr(s, "]", , i)
            n := SubStr(s, i + 1, close - i - 1)
            i := close + 1
        }
        a := Group(s, &i)
        rep := (n = "") ? "sqrt(" a ")" : "((" a ")^(1/(" n ")))"
        s := SubStr(s, 1, p - 1) rep SubStr(s, i)
    }

    ; --- functions ---
    s := StrReplace(s, "\exp(", "ℯ^(")
    s := RegExReplace(s, "\\arc(sin|cos|tan|cot|sec|csc)(?![A-Za-z])", "$1⁻¹")
    s := RegExReplace(s, "\\(sin|cos|tan|cot|sec|csc|sinh|cosh|tanh|coth|ln|log|lg|exp|lim|max|min|sup|inf|det|gcd|arg|deg|dim|ker)\b", "$1")

    ; --- symbols ---
    ; Greek letters
    s := ApplySymbols(s, Map(
        "\alpha", "α", "\beta", "β", "\gamma", "γ", "\delta", "δ",
        "\epsilon", "ε", "\varepsilon", "ε", "\zeta", "ζ", "\eta", "η",
        "\theta", "θ", "\vartheta", "ϑ", "\iota", "ι", "\kappa", "κ",
        "\lambda", "λ", "\mu", "μ", "\nu", "ν", "\xi", "ξ",
        "\pi", "π", "\varpi", "ϖ", "\rho", "ρ", "\varrho", "ρ",
        "\sigma", "σ", "\varsigma", "ς", "\tau", "τ", "\upsilon", "υ",
        "\phi", "φ", "\varphi", "φ", "\chi", "χ", "\psi", "ψ", "\omega", "ω",
        "\Gamma", "Γ", "\Delta", "Δ", "\Theta", "Θ", "\Lambda", "Λ",
        "\Xi", "Ξ", "\Pi", "Π", "\Sigma", "Σ", "\Upsilon", "Υ",
        "\Phi", "Φ", "\Psi", "Ψ", "\Omega", "Ω"
    ))

    ; operators and relations
    s := ApplySymbols(s, Map(
        "\cdot", "*", "\times", "*", "\ast", "*", "\div", "/",
        "\pm", "±", "\mp", "∓", "\circ", "∘", "\bullet", "•",
        "\leq", "≤", "\le", "≤", "\leqslant", "≤",
        "\geq", "≥", "\ge", "≥", "\geqslant", "≥",
        "\neq", "≠", "\ne", "≠", "\lt", "<", "\gt", ">",
        "\ll", "≪", "\gg", "≫", "\approx", "≈", "\sim", "~",
        "\simeq", "≃", "\equiv", "≡", "\cong", "≅", "\propto", "∝",
        "\perp", "⊥", "\parallel", "∥", "\mid", "|", "\vert", "|",
        "\lvert", "|", "\rvert", "|", "\angle", "∠", "\triangle", "△"
    ))

    ; sets and logic
    s := ApplySymbols(s, Map(
        "\in", "∈", "\notin", "∉", "\ni", "∋",
        "\subset", "⊂", "\subseteq", "⊆", "\supset", "⊃", "\supseteq", "⊇",
        "\cup", "∪", "\cap", "∩", "\emptyset", "∅", "\varnothing", "∅",
        "\setminus", "∖", "\forall", "∀", "\exists", "∃", "\nexists", "∄",
        "\neg", "¬", "\lnot", "¬", "\land", "∧", "\wedge", "∧",
        "\lor", "∨", "\vee", "∨", "\therefore", "∴", "\because", "∵"
    ))

    ; arrows
    s := ApplySymbols(s, Map(
        "\to", "→", "\rightarrow", "→", "\leftarrow", "←", "\gets", "←",
        "\leftrightarrow", "↔", "\Rightarrow", "⇒", "\Leftarrow", "⇐",
        "\Leftrightarrow", "⇔", "\implies", "⇒", "\iff", "⇔",
        "\longrightarrow", "→", "\longleftarrow", "←", "\mapsto", "↦",
        "\uparrow", "↑", "\downarrow", "↓"
    ))

    ; calculus and miscellaneous
    s := ApplySymbols(s, Map(
        "\infty", "∞", "\partial", "∂", "\nabla", "∇",
        "\sum", "∑", "\prod", "∏", "\int", "∫", "\iint", "∬",
        "\iiint", "∭", "\oint", "∮", "\prime", "′",
        "\ldots", "…", "\dots", "…", "\cdots", "⋯", "\vdots", "⋮", "\ddots", "⋱",
        "\degree", "°", "\hbar", "ℏ", "\ell", "ℓ", "\aleph", "ℵ",
        "\Re", "ℜ", "\Im", "ℑ",
        "\langle", "⟨", "\rangle", "⟩",
        "\lfloor", "⌊", "\rfloor", "⌋", "\lceil", "⌈", "\rceil", "⌉"
    ))

    ; spacing and escaped characters
    s := ApplySymbols(s, Map(
        "\quad", " ", "\qquad", " ",
        "\,", "", "\;", "", "\!", "", "\:", "", "\ ", " ",
        "\%", "%", "\&", "&", "\#", "#", "\_", "_", "\|", "‖",
        "\(", "", "\)", "", "\[", "", "\]", "", "\\", " "
    ))

    ; --- sub/superscripts and braces ---
    s := RegExReplace(s, "_\{([^{}]*)\}", "_$1")
    s := StrReplace(s, "{", "(")
    s := StrReplace(s, "}", ")")

    ; restore escaped braces
    s := StrReplace(s, Chr(1), "{")
    s := StrReplace(s, Chr(2), "}")
    return Trim(s)
}

; Replaces every key in the map with its value.
; \command keys match whole command names only (so \le does not hit \leq).
ApplySymbols(s, m) {
    for k, v in m {
        if RegExMatch(k, "^\\[A-Za-z]+$")
            s := RegExReplace(s, "\Q" k "\E(?![A-Za-z])", v)
        else
            s := StrReplace(s, k, v, true)
    }
    return s
}

Group(s, &i) {
    while (SubStr(s, i, 1) = " ")
        i++
    c := SubStr(s, i, 1)
    if (c != "{") {
        i++
        return c
    }
    depth := 0, start := i + 1
    Loop {
        c := SubStr(s, i, 1)
        if (c = "")
            return SubStr(s, start)
        if (c = "{")
            depth++
        else if (c = "}") {
            depth--
            if (depth = 0) {
                i++
                return SubStr(s, start, i - 1 - start)
            }
        }
        i++
    }
}