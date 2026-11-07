# BrickStack Copilot instructions

## Build, test, and lint

Build the Delphi project from a RAD Studio command prompt (or after calling that installation's `rsvars.bat`):

```bat
msbuild BrickStack.dproj /t:Build /p:Config=Debug /p:Platform=Win64
```

The project defaults to Debug/Win64. Release builds use:

```bat
msbuild BrickStack.dproj /t:Build /p:Config=Release /p:Platform=Win64
```

The executable and compiler output go to `Bin\Win64\Debug` or `Bin\Win64\Release`. There is no automated test project or configured lint command in this repository, so there is no single-test command.

## Architecture

- `BrickStack.dpr` is the VCL application entry point and lists the forms and units compiled into the app. Forms are MDI windows: `UFrmMain` owns shared configuration, image cache, and the FireDAC SQLite connection pool; child windows and dialogs implement search, collections/set lists, set/parts views, and import/export.
- A form's component layout and event wiring are in its matching `.dfm`; its behavior is in the `.pas`. Keep these paired when changing a form. Add new compiled units to the project source/project file as needed.
- UI workflows query the local SQLite database through FireDAC. `TFrmMain.AcquireConnection` / `ReleaseConnection` share pooled connections; query results are mapped into objects in `Src\Data` and displayed in the forms. The local BrickStack-owned tables use the `BS` prefix, while catalog/inventory data comes from the Rebrickable database.
- `Src\Scripts\UBSSQL.pas` defines BrickStack tables, indexes, and database schema version constants. `UDlgUpdateDatabase` applies initialization/upgrades and `UFrmMain` checks the database version. A schema change must keep the version constants, creation scripts, and upgrade path consistent.
- Cross-window actions and refreshes are dispatched through the custom `WM_*` messages and payload records in `Src\UPostMessage.pas`, handled by `UFrmMain`; follow that route rather than coupling child forms directly to one another.
- `TConfig` in `Src\UConfig.pas` reads and writes `BrickStack.ini` beside the executable, including window state and user preferences. Shared enum/constants live in `Src\Data\UConst.pas`; user-facing string constants are in `Src\UStrings.pas`.
- Rebrickable API and CSV workflows and BrickLink XML import/export are implemented in the import/export dialogs. The API key is configured separately; README notes that passwords are not stored and the temporary authentication token is persisted only when explicitly enabled.

## Repository conventions

- Keep user-visible UI text in `UStrings.pas` and use the existing shared string constants in forms/dialogs.
- Use parameterized FireDAC queries for values and release every acquired connection in a `finally` block. Keep SQL table and schema changes aligned with `UBSSQL.pas` and the database update dialog.
- Reuse the main form's shared configuration, image cache, and connection pool instead of creating parallel application-wide instances.
- Search results and other potentially large UI lists use owner-managed object lists and virtual/custom drawing; preserve their object ownership and existing virtual-list behavior when changing display code.
- For new code, prefer inline variable declarations near their first use instead of listing all locals at the top of a function. Do not move existing declarations just to match this preference.
- Put `begin` on the same line as `for ... do`, `if ... then`, and `else`, including when the condition spans multiple lines (put `begin` on the line containing `then`).
- Keep `else` on the same line as the preceding `end`, including `end else begin` and `end else if ... then begin`.
- Keep routine signatures on one line when they fit clearly; wrap only signatures that would become excessively long.
- Apply these style preferences to new code and directly changed blocks only; do not reformat unrelated existing code.
- Apply the style while implementing the requested change. Do not write code in a different style and rely on a later broad formatting pass to correct it.
- For BrickStack2 Pascal-specific style examples, follow `.github/instructions/brickstack2-delphi.instructions.md`.
