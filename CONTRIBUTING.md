# Contributing

Issues and pull requests are welcome at
[the issue tracker](https://github.com/m7hamed-dev/save_points_pdf_templates/issues).

## Before you open a PR

```bash
dart format . && flutter analyze --fatal-infos && flutter test
```

CI runs the same three on the package and on `example/`, plus
`flutter pub publish --dry-run`. `--fatal-infos` means a lint hint fails the
build, so run it locally rather than finding out on the PR.

## Testing a rendering package

The output is a PDF, so "it compiles" proves very little. Three kinds of test
carry the weight here, and a change usually needs one of them:

**Read the drawn output, not the widget tree.** `test/rtl_layout_test.dart`
pulls text-showing operators out of the page's content stream and asserts on
where the glyphs landed. This exists because the widget tree is *identical*
in both directions — it is the renderer that decides what ends up on the
right, so a mirroring bug is invisible to a tree-level test. Anything about
direction, column order or line breaking belongs there.

**Assert the document, not the bytes.** `expect(bytes, startsWith('%PDF-'))`
passes for a blank page. Where you can, assert a property the reader would
notice: which column is bold, that a normal invoice fits on one page, that
the renderer never asked the font for a glyph it does not have
(`test/arabic_support_test.dart` captures the missing-glyph warning through
a `Zone`).

**Render both directions.** Arabic is not a translation of the layout, it is
a mirror of it. `test/widgets_test.dart` draws every `PdfUi` primitive and
every `PdfSections` block in both, under all three presets, with empty and
over-long input.

## Fonts

The package ships none on purpose. Tests that need Arabic load the example
app's asset from disk.

The renderer asks a font for the legacy Arabic Presentation Forms-B
codepoints instead of applying OpenType shaping. Most Google Fonts Arabic
families — Cairo and Tajawal among them — never map that block, so a
word-final `ي` after `ر`, `ا`, `د`, `و` or `ز` is silently dropped. If you
change the example's font, check the replacement carries `U+FEF1`.

## Design changes

The three presets are meant to be three documents, not three palettes. If you
change a token, render all three in both directions and look at them before
pushing — `theme_test.dart` guards the relationships between tokens, not
whether the result is any good.

Watch the page count. Whitespace is what pushes a signature block onto a
second page, and a short invoice that spills just to carry its signatures
looks like a mistake. There is a test for it.

## Commits

Explain what was wrong and why the change fixes it. A reader six months from
now needs the reasoning, not a restatement of the diff.
