# SafePath (working name)

Offline emergency companion: First Aid (EN/AR), Maps (cached), Library, SOS, content-pack updates.
Radio and Chat are placeholders for later phases.

## Get the APK without installing anything
1. Create a free GitHub account and a new repository.
2. Upload all files of this folder (keep the `.github` folder).
3. Open the repository > Actions > "Build Android APK" > Run workflow.
4. When it finishes (about 5 minutes), download `safepath-apk` from the run page and send the APK to friends.

## Updates
Host a `manifest.json` (see lib/services/content_service.dart) and put its link in `manifestUrl`.
