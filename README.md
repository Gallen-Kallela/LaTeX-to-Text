# LaTeX to Text

A small tool that converts selected LaTeX math into plain text. Select a formula, press **Ctrl+Shift+L**, and the converted text is on your clipboard. Download the .exe file from the releases section or use scoop to get it (detailed instructions for scoop below). For a more customizable experience download the .ahk file.

## Usage

1. Select LaTeX text.
2. Press **Ctrl+Shift+L**.
3. A small "Copied!" pop-up appears.
4. Paste with **Ctrl+V**.

Example:

```
\frac{1}{2}
```

becomes

```
((1)/(2))
```

## What it converts

- **Fractions and roots:** `\frac{a}{b}` → `((a)/(b))`, `\sqrt{x}` → `sqrt(x)`, `\sqrt[n]{x}` → `((x)^(1/(n)))`, `\binom{n}{k}` → `nCr(n,k)`
- **Functions:** `\sin`, `\cos`, `\tan`, `\sec`, `\ln`, `\log`, `\lim`, `\max`, `\min` and others, plus inverse trig (`\arcsin` → `sin⁻¹`)
- **Greek letters:** all lowercase and uppercase (`\alpha`, `\theta`, `\Delta`, `\Omega`, ...)
- **Operators and relations:** `\cdot`, `\times`, `\div`, `\pm`, `\leq`, `\geq`, `\neq`, `\approx`, `\equiv`, `\propto`, ...
- **Sets and logic:** `\in`, `\subset`, `\cup`, `\cap`, `\emptyset`, `\forall`, `\exists`, `\neg`, ...
- **Arrows:** `\to`, `\rightarrow`, `\Rightarrow`, `\iff`, `\mapsto`, ...
- **Calculus and other symbols:** `\infty`, `\partial`, `\nabla`, `\sum`, `\int`, `\ldots`, `\hbar`, ...
- **Number sets:** `\mathbb{R}`, `\mathbb{N}`, `\mathbb{Z}`, `\mathbb{Q}`, `\mathbb{C}`
- **Text and formatting:** `\text{...}`, `\mathrm{...}` and `\vec{...}` keep their content, `^\circ` → `°`
- **Subscripts and braces:** `x_{1}` → `x_1`, remaining `{ }` become `( )`

Anything not listed is left unchanged.

## Running

Double-click `latex_to_text.exe`. It runs in the background (look for the white "L" icon in the system tray) and starts automatically with Windows. Right-click the tray icon and choose **Exit** to stop it.

## Customizing

To customize the tool you need the `latex_to_text.ahk` file and [AutoHotkey v2](https://www.autohotkey.com/). Open the `.ahk` file in a text editor and change:

- **Hotkey:** change `$+^l::` at the top of the hotkey block (and the `Send "+^l"` line).
- **Pop-up text:** change `"Copied!"`.
- **Pop-up transparency:** change `toastAlpha` (lower = more transparent).
- **Symbols:** add a pair like `"\gamma", "γ"` to one of the `ApplySymbols` lists.

## Installing with Scoop

If you use [Scoop](https://scoop.sh), you can install the tool from the command line:

1. Add the bucket:
   ```
   scoop bucket add gallen-kallela https://github.com/Gallen-Kallela/scoop-bucket
   ```
2. Install the app:
   ```
   scoop install latex-to-text
   ```
3. Start it by searching for **LaTeX to Text** in the Start Menu, or by typing `latex_to_text` in a terminal.

To update to a newer version:

```
scoop update latex-to-text
```

To uninstall:

```
scoop uninstall latex-to-text
```
