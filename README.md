# ReasonML Playground (Native App)

Very rough cut of an app version of the ReasonML playground. Aimed as a proof of concept to see if people like the idea.

[Download it for free on iPhone and iPad](https://apps.apple.com/gb/app/reasonml/id1507769834)

Uses SwiftUI. We should consider using React Native + ReasonML for Android support and possibly share code with a web version. If we go that route, we can use react-native-threads for background tasks.

Below is a list of stuff I would like to add, but we should properly consider React Native first.

- Syntax highlighting
- Line numbers
- React output view
- Customisable layout
- Copy and paste from console
- JSON printing in console
- ANSI formatting in compilation errors and possibly console
- Better compilation error formatting including jump to selection
- Deeplinking for playground URLs, and ability to share projects (needs ReasonML to add manifest to their site)
- File save/import/export
- macOS app
- Text area content insets broken when keyboard visible with a toast
