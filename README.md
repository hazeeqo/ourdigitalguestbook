# Little Moments — wedding guestbook prototype

This is a browser-only prototype for the Haziq & Aina wedding guestbook.

## Try it

Open `index.html` in a current browser to try photo selection, compression, captions, and the local gallery. To try the live camera on a computer, serve the folder from localhost (for example, with VS Code Live Server). Phones need the page served over HTTPS for camera permission.

Photos are resized to at most 1920 pixels on the longest side, converted to JPEG at 82% quality, then saved in this browser's IndexedDB. The gallery is local to this browser and device. Clearing browser data removes the demo photos.

## Before sharing with guests

This prototype does not upload photos or wishes to a shared database. Its host-view button is a placeholder. A production version needs a separate guestbook backend with image storage, database records, upload limits, and real host authentication/moderation. Do not add a private API secret to browser JavaScript.
