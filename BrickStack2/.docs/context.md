# Delphi 13 project files

## Creating or adapting a project

- Prefer creating the project in RAD Studio 13 and saving it there, or start
  from a RAD Studio 13 project that has already saved successfully. Use that
  `.dproj` as the template instead of hand-writing a minimal project file.
- Preserve the IDE-generated `ProjectExtensions` / `BorlandProject` section.
  It carries project metadata used by the IDE when saving; a project can be
  valid XML and build while still crashing in RAD Studio if this metadata is
  missing.
- When adapting a template, give the new project a unique `ProjectGuid` and
  update the project name, main `.dpr`, source references, executable/output
  names, and any source or deployment references in `ProjectExtensions`.
  Keep platform selections and configuration metadata consistent with the
  intended targets.
- Open the resulting project in RAD Studio, save it, and build it there to
  verify both IDE persistence and compilation. XML parsing alone is not enough.

## BrickStack2 save failure

The initial BrickStack2 projects were minimal `.dproj` files without the
RAD Studio `ProjectExtensions` / `BorlandProject` section. Saving the UI
project in RAD Studio 13 raised a stack trace through
`Xml.XMLIniFile.TXmlIniFile.FindXmlNodeOrAdd` and `NormalizeIdent`.

Changing the compiler selector and project version did not resolve the save
failure. A temporary project based on the working BrickStack project, adapted
to the BrickStack2 UI settings, saved successfully. Copying its IDE-generated
project extensions into `Src\UI\BrickStack2UI.dproj`—with the UI source and
output names updated—allowed the project to save and compile. The same metadata
was then added to the backend and tests project files.

For future projects, treat missing IDE-generated metadata as a possible cause
when a `.dproj` builds but crashes while RAD Studio saves it. Do not remove or
blindly reuse extension metadata: adapt the source, outputs, platforms, and
deployment entries for the specific project.
