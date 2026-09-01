# save_points_pdf_templates — example

Renders every template in the package and previews it with `printing`.

```bash
flutter run
```

- **Arabic / RTL** switches the font (Cairo), the currency and the layout
  direction; turn it off for the Latin (Inter) build.
- The accent chips swap `PdfTheme` presets at runtime.

Fonts live in `assets/fonts/` and are declared in this app's `pubspec.yaml` —
the package itself ships none, so you choose the typeface and only pay for the
bytes you actually bundle.
