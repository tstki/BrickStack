# BrickStack changelog

## Version (0.0.0.10)
- Search results limiter moved to settings.
- Added "in my collection" option when searching.
- Search results can now be sorted, and have the ability to show/hide text.
- Search parts
- Remember search parameters (except search field)

## Version 20251130.1915 (0.0.0.9)
- CSV import overhaul.
- Use image thumbnails instead of full size for better performance, less disk space and reduced memory footprint.
- Added doubleclick action setting.
- Parts list sorting and filtering.
- Added several more settings and reorganized the config dialog.
- Reorganized BrickStack.ini into sections - NOTE: Your old settings will be unavailable due to this! You can manually move them to the sections by editing the .ini
- Config file load/save optimizations.
### Fixes:
- Delete set fixed.
- Scroll wheel causing click fixed.
- RB CSV export fixed.
- Improve loading .png files that are somehow named .jpg in the database.

## Version 20251122.1201 (0.0.0.8)
- Database version checking.
- Using rb.db from https://github.com/ojuuji/rb.db
- Dialogs auto-update when sets are added to collections.
- Many new features in setlist. Among which: Treeview, editing rows.
- Table sorting.
- Drag and drop search results to collections or set lists.
- Drag and drop sets to other collections.
- Lots of right click menu improvements.
### Fixes:
- Parts printing fixed.

## Version 20251005.1150 (0.0.0.7)
- Put some meat on the bones of the previously very empty help screen.
- Hide inventory version from parts if only a single version is available.
- Search and Parts list are now virtual, and have grid scaling.
- Right click menu in search dialog.
- Missing images are a thing - we now show the "missing image" when none are available.

## Version 20250823.1210 (0.0.0.6)
- Basic database creation on startup.
- Automatically download and import base table info from Rebrickable.

## Version: 20240706.time (0.0.0.5)
- Ditched DBXSQLite in favour of FireDAC SQL for SqLite. Less code, more flexibility "select as" actually giving the right name.
- Restore window position, open state, and size
- Lotsa filters
- Removed indy and ssl. Now handled by the system.
- Upgraded project from Delphi CE11 to CE12.1
- Darkmode option

## Version 20240523.1837 (0.0.0.4)
- Search function to find sets
- Set details screen with parts list
- Parts display
- About screen improved
- Image download and cache
- Remember whether setlists/set window was open and restore its open state
- Dont load Images in a scrollbox if they are not in the visible viewport

## Version 20240511.1633 (0.0.0.3)
- Added sqlite.dll
- Added rebrickable database

## Version 20240504.1549 (0.0.0.2)
- Basic MDI window
- Config settings for api key and base url
- About screen
- Implemented login window for token acquisition
- Basic collections window with import ability

## Version 20240421.1907 (0.0.0.1)
- Initial commit. Not much here