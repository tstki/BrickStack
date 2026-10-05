# BrickStack web UI — plan

Source repo: https://github.com/tstki/BrickStack (Delphi, currently an MDI desktop app).
Goal: replace the MDI interface with a single-window, browser-based UI served by a Delphi backend. The same UI is used on the desktop, when self-hosted and on a public share link.

## Files in this project
- `BrickStack Layouts.dc.html`: three static layout options that replace MDI (1a tabs plus sidebar, 1b master–detail with history, 1c docking). **1b was chosen.**
- `BrickStack Web.dc.html`: v1 clickable demo of 1b (no accounts).
- `BrickStack Web v2.dc.html`: v2 clickable demo with users, roles and editing. **Current version.**
- `export/BrickStack-demo.html`: single-file bundle of v2 you can download.

## Architecture decisions
- **Backend:** Delphi REST server. Open-source options: Horse (MIT) or mORMot 2 (fast, SQLite/ORM built in). WebBroker also works for single-user use. TMS WEB Core is excluded because it's commercial.
- **Frontend:** plain HTML/JS (optionally htmx, or Vue/Svelte later). Bootstrap (MIT) is fine for the responsive grid.
- **Desktop build:** Delphi exe that starts the server and opens the browser, or embeds `TEdgeBrowser`.
- **Self-host:** the same server as a service. mORMot and Horse also run on Linux.
- **Rebrickable images:** never hotlink them. The server downloads each image once, resizes it (64 / 240 / 800 px, e.g. with Skia4Delphi), stores it as `sets/{id}_{size}.webp` and `parts/{part}_{color}_{size}.webp`, and serves it with `Cache-Control: immutable`. Downloads go through one queue throttled to about 1 request per second, with an identifiable User-Agent and backoff on 429 responses.
- **Secrets:** the Rebrickable API key stays on the server, one per user. It is never sent to the browser.
- **Public share:** a read-only route `/share/<token>` with no login, sync or config. The server has to listen on all interfaces, or sit behind a reverse proxy, for the link to work from other devices.

## UI structure (1b)
- **Left rail (72px, collapsible to 248px):**
  - A hamburger button at the top.
  - The yellow logo, which goes to the Overview.
  - Sets, Parts, Minifigs and Search for everyone; Sync (not for viewers); Users (admins only).
  - Config at the bottom. The expanded rail also shows About and the version.
- **List pane (340px):** the items of the current section (set lists as a segmented control, filter, status chips).
- **Detail pane:** a header with Back/Forward, breadcrumbs (only the last crumb shortens, min 80px), sync status (only the dot below 1100px), a dark/light toggle and an avatar menu.
- **Mobile (<768px):** one pane at a time, a top app bar (menu or back, title, theme, avatar) and the rail as a slide-out drawer.
- **Screens:**
  - Overview: totals, set-list progress, incomplete sets.
  - Set detail: parts, minifigs and notes tabs; inventory check with −/+ per part.
  - Part detail: used in sets, loose quantities.
  - Part lists: All, one per drawer, and a Missing list.
  - Minifig detail, Search, Sync (log, image queue), Config, Account, Users, About.
- **Theme:** Light, Dark or System, stored per user.

## Users and roles
- Each user has their own collection.
- **Admin:** manages users and server settings, and has their own collection.
- **Member:** edits their own collection.
- **Viewer:** read-only access to one chosen member's collection.
- **Accounts:** admins invite people (by link or with a set password). Self sign-up can be toggled on or off, and the role for new sign-ups is configurable.
- **Account page:**
  - Profile (name, email, avatar colour).
  - Change password (this signs out other sessions).
  - Signed-in devices, with sign-out per device.
  - API tokens (read-only or read and write, shown once).
- **Config:**
  - Personal preferences: theme, start page, default list.
  - Own Rebrickable account and "share my collection" (members).
  - Admin-only server section: accounts, image cache, network.

## Editing features
- Add a set by number, looked up on Rebrickable. `10300` is normalised to `10300-1`. Adding a set you already have increases its copies.
- Manual or MOC entries: name, optional number (otherwise auto `MOC-000N`), theme, parts count.
- Per set: change copies, move to another list, remove (click twice to confirm).
- Create, rename and delete set lists. Deleting a list also removes its sets, after confirming.
- Bulk import from a Rebrickable CSV or from the linked account. The preview marks each row New, Adds a copy or Not found.
- Loose parts: add parts to a part list by searching for them; create and delete part lists.
- Minifigs: add from the catalogue, change copies, remove.

## Visual system
- BrickStack Design System tokens (Lexend, primary blue #2958CD, dark #20294F, yellow accent #F5B83D used sparingly), 8–12px radii, Lucide line icons.
- The dark theme uses CSS variables `--bs-*` switched with `data-theme` on the root.
- The demo copy is English and the data is illustrative. Images are placeholders.

## Known gaps / next steps
- The public share page itself (the read-only view a visitor sees) is not mocked yet.
- There is no parts-list import for manual/MOC sets yet.
- Part lists can't be renamed yet (only created and deleted).
- In the offline bundle, icons whose name changes at runtime (rail items, theme toggle, menu) still load from the unpkg CDN. Fix by inlining the SVGs.
- Map this plan onto BrickStack's real Delphi units and database schema once the source is reviewed.

## How to regenerate
Give this file plus the v2 file to the assistant, then ask for changes, for example "add the public share page based on plan.md".
