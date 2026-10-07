OptimosApp — Capture. Optimize. Convert.
=========================================

Requires a Mac with Apple silicon, running macOS 26 or later.

INSTALL
1. Drag OptimosApp into the Applications folder.
2. This build is not signed by Apple, so macOS will not open it at first. Do ONE of these:
   a) Open Terminal and run:   xattr -dr com.apple.quarantine /Applications/OptimosApp.app
      then open OptimosApp normally.
   b) Or open OptimosApp, close the warning, then go to System Settings > Privacy & Security,
      scroll down and press "Open Anyway" next to OptimosApp.
3. OptimosApp lives in the menu bar (top right). The first time you capture, macOS asks for Screen
   Recording permission: allow it in System Settings > Privacy & Security > Screen & System Audio
   Recording, then quit and reopen OptimosApp.

USE
- Control-Option-Command-4: capture an area or window (Space switches between them).
- Control-Option-Command-3: copy the whole screen.
- Control-Option-Command-O: optimize images (drop files or folders on the window).
- Menu bar icon > Preferences changes shortcuts, save location, formats and more.

NOTES
- Because the app is not signed, macOS may ask for Screen Recording permission again after you
  install an update. If captures stop working, remove OptimosApp from that list, add it again,
  and restart the app.
- OptimosApp bundles open-source tools (oxipng, pngquant, libjpeg-turbo) under their own licenses,
  listed in OptimosApp.app/Contents/Resources/licenses.
- Questions or problems: contact Tarik Omercehajic.
