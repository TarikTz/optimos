export const FAQ_DATA = [
  {
    question: "Is OptimosApp really free?",
    answer:
      "Yes. It is open source under the MIT license: free to use, change and share. There is no account, subscription or ad.",
  },
  {
    question: "How does hiding sensitive information work?",
    answer:
      "Draw a box over an API key, an email address or a face and choose Pixelate or Blur. The effect is applied to the pixels of the image itself when you copy or save it, so the original detail cannot be recovered from the file.",
  },
  {
    question: "Does it upload my screenshots or images?",
    answer:
      "No. Capturing, marking up, optimizing and converting all happen on your Mac. Nothing is sent anywhere, and the app has no tracking.",
  },
  {
    question: "Is there a Windows version?",
    answer:
      "It is in development as a separate app, with the same features, and the plan is to publish it on the Microsoft Store. Follow the project on GitHub to see when it is ready.",
  },
  {
    question: "Why does macOS warn me the first time I open it?",
    answer:
      "The app is not signed and notarized with an Apple Developer account yet. Run the one line in the Install section, or press Open Anyway in System Settings > Privacy & Security, and it opens normally from then on.",
  },
  {
    question: "What does it need to run?",
    answer:
      "A Mac with Apple silicon running macOS 26 or later. The optimizer tools are built in, so there is nothing else to install.",
  },
  {
    question: "Will it overwrite my original images?",
    answer:
      "When you optimize a file without changing its format, it is replaced, but only if the new file is smaller, and Undo restores the originals until you close the window. Converting to another format always writes a new file and keeps the original. In Preferences you can choose to save copies instead.",
  },
  {
    question: "Which formats does it support?",
    answer:
      "PNG, JPEG and WebP can be optimized and converted in any direction. HEIC (iPhone photos), TIFF and BMP can be opened and converted to PNG, JPEG or WebP; those originals are never replaced.",
  },
];
