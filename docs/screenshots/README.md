# Screenshots and demo recording

Captures for the assignment submission go in this folder. File names below are the
ones the root README links to; replace the placeholders with real captures taken on
the iPhone 17 Pro simulator (or a device) with no debug banner and no test data.

| File | Screen | How to reach it |
|---|---|---|
| `01-explore.png` | Explore feed (editor's picks) | Launch the app |
| `02-search.png` | Search results with the hit count | Type a term, e.g. "desert" |
| `03-details.png` | Image Details | Tap a tile |
| `04-sign-in.png` | Sign in / Create account | Favourites tab while signed out |
| `05-favourites.png` | Favourites with saved images | Save a few images, open the Favourites tab |
| `06-favourites-empty.png` | Favourites empty state | Signed in, nothing saved |
| `07-profile.png` | Authenticated Profile | Profile tab while signed in |
| `08-offline-favourites.png` | Favourites while offline (optional) | Turn off the network, reopen Favourites |

Capture from a booted simulator with:

```sh
xcrun simctl io booted screenshot docs/screenshots/01-explore.png
```

## Demo recording (45–90 s)

1. Explore feed loads; scroll a little.
2. Type a search term; results and the hit count appear.
3. Scroll to the bottom twice to show infinite scrolling ("PAGE 2" footer).
4. Open Details; pinch-zoom the full-screen viewer briefly.
5. Tap "Save to favourites" (sign in when prompted the first time).
6. Open the Favourites tab; the image is there.
7. Kill and relaunch the app; the session is restored and the favourite is still there.
8. Open Details from Favourites, tap the download circle, "Saved to Photos" appears.
9. Open Profile; show the account and the "Saved images" row; log out.

Record with:

```sh
xcrun simctl io booted recordVideo --codec h264 docs/screenshots/demo.mp4
```

and stop with Ctrl-C.
