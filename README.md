# SafePath (working name)

Offline emergency companion: First Aid (EN/AR, illustrated), Maps (live GPS), Library (categories + search),
SOS (detects your country offline), signed content updates that can be shared phone to phone.

## Build
- Push to GitHub. Actions builds the Android APK and publishes the web version to GitHub Pages.

## Updating content
- Use SafePath-Publisher.html (separate download, NOT in this repo) to sign a new .safepath file.
- Offline: share the file to other phones. Online: upload it to web/packs/latest.safepath.
- Never commit the private key file.
