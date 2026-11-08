# Haziq & Aina — wedding guestbook

A mobile-first, disposable-camera-inspired guestbook for the 11 April 2027 wedding at Dewan PICC.

## Try locally

Open `index.html` in a current browser to use the local preview. Camera access on a phone requires an HTTPS page (GitHub Pages provides HTTPS). Without Supabase configuration, photos stay in that browser's IndexedDB and are not shared.

## Supabase setup

1. Create a Supabase account and a new **Free** project. Choose a region near Malaysia. Keep the database password private.
2. In **Storage**, create a public bucket named `guest-photos`. Set its maximum file size to **512 KB** and allowed MIME type to **image/jpeg**. The gallery is designed for public photos, so public URLs can be viewed by anyone.
3. Open **SQL Editor**, paste all of `supabase-setup.sql`, and run it. It creates the guest photo table, row security rules, live gallery updates, and the 1,000-photo / 2,000-file caps.
4. Open **Connect** (or **Settings → API Keys**) and copy the **Project URL** and **Publishable key** (starts `sb_publishable_`). Add these to `supabase-config.js` as `url` and `publishableKey`.
5. Upload the updated site files to the GitHub Pages repo. The app should then show **Shared album connected**.

Never put the Supabase **Secret key** (or legacy `service_role` key) in the website. The publishable key is designed for browser code and is limited by the SQL row-level security rules.

## Image handling and limits

Before upload, the app applies the selected film look, resizes the photo, converts it to JPEG, and iteratively compresses it to at most **500 KB**. It also makes a small gallery thumbnail. The bucket has a **512 KB per-file** server-side limit; SQL restricts the bucket to 2,000 objects (one photo and one thumbnail for each of 1,000 album entries) and blocks database entries beyond 1,000. The gallery loads 24 thumbnails at a time; tapping a card loads the full photo.

The Supabase Free project can pause after a week of inactivity. Check the project and resume it before the wedding if needed. Free storage and bandwidth are limited; review usage before sharing the QR code widely.
