# More of a todo / idea list than a roadmap, but here goes:

## Application:
- Note bulk downloads may be slow and need to be throttled to +- 1 per second.
- Closing a dialog should store it's last location, not just on application close
-- Add option for this, since MDIs are kinda jumpy when reloading location.
- Auto updater through github releases page
-- Show dialog on startup if detected, ask user if they want to update - and give option to not remind again for this version.
-- exe can replace itself through rename.

### Welcome:
- Reference to tutorial/about and mandatory database creation steps and updating.
- Choose a language (with flag icon) - also in settings.

### Logging:
- Optional log files for communication and debugging.
- Make sure passwords are not logged to the _token endpoint
- Make sure any token is not logged.

### Database:
- Dont use "select *" but get the exact columns
- Auto Database updater improvements
- Comma separated search input, so you can search for sets "and / or"
- Add DB column and rename BSSetLists to BSCollection, add column for type
- Deleting a set/collection should ask the user to move all parts/sets to a new inventory, or delete (including all parts)

### Optimizations:
- Multithreading http calls for smoother user experience (mind error 429)
- Implement FastMM5 for memory leak checking and object creation performance. https://github.com/pleriche/FastMM5/releases
- Inline small functions.
- More multithreading - performing the query and convert to internal values, converting internal values to display list.
- Configure result limitation so the user cant query the whole database with one number.
- progressdialog in case an operation takes long (like import/export)
- Cleanup unused functions to keep the .exe smaller

### Throttling and request slowing:
- Handle error 429: Add a mandatory delay between requests
- Request was throttled - you are sending too many requests too fast.
- Normal user accounts are allowed to send on average one request/sec, with some small allowance for burst traffic.
- Example response: { "detail": "Request was throttled. Expected available in 2 seconds." }
- Parts call: /lego/parts/?part_nums=3001,3002,3003&inc_part_details=1

### Analytics:
- Show graphs of each theme / year / part count of sets you own

## API
### Get user's inventory
- Ability to export inventory per group to rebrickable csv/xml

## Windows
- Collection details (shows selected collection's details / custom fields / statistics)
- Collection content (shows selected collection's set content)
- Multiple collections (vertical and horizontal)
- "layout" set for all windows to switch window placements configured by the user.
- Hamburger menu if window size is too thin.
- Expand about screen
- Fix window sizes and anchors
- Helpfile / tutorial / common shortcuts
- Sorting grids

### Settings:
- Add option to show/hide columns for collection / setlist.
- Add ability to add custom fields.
- Option to store backup files on changes / periodically.
- Slider setting for delay between image downloads.
- Search options box above treeview.
- Caps lock is active warning in login dialog
- Default import / export path (just remember last used)
- Option to allow multiple collections windows
- Option to allow multiple collection windows
- Check for updates / autoupdater (through github binary distribution)
- Options for default image quality for parts / sets / other. Too high by default, limit is 1000px 128 for parts and 256 for models would be better as default.
- Choose UI elements in search results / parts (several template layouts, with example)
- Option to treat newly added sets as having all parts

### Configure desired columns when printing - preferably on the dialog itself by showing the config dialog and it's related settings.
- Also multiple columns - ask in dialog, and make a preview
- Look into Skia library https://github.com/skia4delphi/skia4delphi

### Collection window:
- Import from CSV/Xml and other sources.
- Edit (change current selected row) -> show dialog with options such as: icon / name / description / custom fields
- Drag n drop to change custom order.
- Add warning on export type, that not all settings may be supported by the receiving party. With button for "dont show again"
- Support filtering by custom tag
- Give custom tags / columns a user selectable icon
- Option to open selected collections in the same window, or a new window for each. (extra work for saving dialog dimensions)
- Right click mark as built
- Add (non editable) "all your sets" table entry to view your collection and filter from there.
- Remember column widths
- Add inventory version to set selection, so export knows what version to use rather than v1
- Support filtering separate figures or all figures in your sets.
- Text filter (show/hide text matches by name)
- Export parts lists across multiple sets or inventories. so you can easily order what you need.
- Show owned sets. Show > in front of owned sets in case of multiple, and open as tree view.
-- Sub-setlists, in collections screen.
- Select / Edit parts from this window only. (update help to reflect this) Stored between sessions.
- View all parts in this collection
- View all "missing" parts in this collection. (filter?)
- Deleting a set should also delete all parts.

### Parts window:
- Improve inventory version handling.
- Export parts.
- Add to collection
- Show minifigures as part of the set parts
- Export set parts - CSV

### Collections:
Export collection:
- Choose format
- Choose overwrite / keep
Import collection:
- Choose format
- Choose overwrite / keep
- Import as bulk input (line separated set numbers, part numbers or minifigure IDs)

## Search:
- Option to show search as image panels or table with text, and image on hover
- Prevent text overlap (cut off by replacing text with ..."
- Also to future part search dialogs
- When searching for minifigs, also search "in sets"
- Configure next/prev page results, in case results are a lot. (limit 10 offset 10) or load while scrolling.
-- Should be available in the API
- Add "force refresh from external" button for sets / images under a setlist.
- Minifigure search and enrichment:
-- Search set, links to minifig.
-- Set has theme available for filtering, and year. Search figure by name or "number"
-- select * from inventories where set_num = '4200-1';
-- select * from inventory_minifigs where inventory_id = 9677;
-- select * from minifigs where fig_num = 'fig-001386';
- Menu option: Find alternative colors (for part search)
- Menu option: Find sets with this part (for part search) - expand with special search later.
- Include search by year (by joining set, and sorting by year ascending)

### Search parts in:
- Search for parts in sets, to find sets
- Combine multiple parts to search for
- Show what sets searched parts can be found in

## Known issues:
- Selecting a grid cell at the bottom, scrolls all the way to the bottom of the search result.
-- https://stackoverflow.com/questions/7118194/how-can-i-disable-the-scroll-into-view-behavior-of-tscrollbox
- Some images are named ".jpg" but are actually bitmaps, or png. (not our fault, really!)
- "3001pr004" and other parts with different external references do not allow part lookup at this time.