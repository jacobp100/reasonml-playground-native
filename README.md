# ReasonML Playground (Native App)

Very rough cut of an app version of the ReasonML playground. Aimed as a proof of concept to see if people like the idea.

[Download it for free on iPhone and iPad](https://apps.apple.com/gb/app/reasonml/id1507769834)

Uses SwiftUI. We should consider using React Native + ReasonML for Android support and possibly share code with a web version. If we go that route, we can use react-native-threads for background tasks (see below).

Below is a list of stuff I would like to add, but we should properly consider React Native first.

- React/web output view
- JSON printing in console
- Identify ReasonML arrays and lists, and provide better formatting
- Customisable layout
- Deeplinking for playground URLs, and ability to share projects (needs ReasonML to add manifest to their site)
- File save/import/export
- macOS app

## Notes for React Native

We can probably assume that any syntax highlighting or nice editor features are going to be native components. Even though this can technically be done from RN (you can put `<Text>` components inside a `<TextInput>`), it's likely to not be performant enough.

Currently any js build of BuckleScript will be 4mb+, and that is enough to crash the Metro bundler. Running node with 6gb of old space fixes this - but it'll take 10 minutes.

Doing this, you can generate a static jsbundle file, and then you can modify the native code for react-native-threads to force it to load all bundles from the bundled files (like it does in production). That mostly works - you'll be able to compile and format code with this mechanism.

If we can figure out how to get a smaller bundle, that would help a lot. Currently we bundle reason (for refmt) and BuckleScript's playground (which I think includes refmt again). There's probably a lot of room for improvement here. We can also look into something like Haul (or related packages) to generate the jsbundle - that'll be much faster because we can sidestep babel.

That's all quite a lot of hassle for now, and makes development not fun. So I think for now, it makes sense to continue with SwiftUI development, focusing mostly on the runtime bundle in JS (under `/runtime`), which can be shared when things improve. The UI will be pretty minimal in this project, so a rewrite where we can reuse the runtime will be quite quick.
