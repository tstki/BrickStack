---
description: "Use when changing BrickStack2 Delphi Pascal source. Covers local-variable, control-flow, signature, and compile-validation conventions."
name: "BrickStack2 Delphi Conventions"
applyTo: "BrickStack2/**/*.pas"
---

# BrickStack2 Delphi conventions

- Follow these rules while writing or changing code, not as a later broad cleanup. Keep unrelated existing code untouched.
- Prefer inline local variables near their first use. When a local is initialized immediately, put its type and initializer in one declaration instead of declaring it and assigning on the next line. For example:
  ```pascal
  var GenerateRandom: TBcryptGenRandom := TBcryptGenRandom(GetProcAddress(LibraryHandle, 'BCryptGenRandom'));
  ```
- Include an explicit type when it is needed for Delphi to resolve an inline initializer correctly, especially for dynamically loaded function pointers. Do not replace such a type with inferred `var Name := ...` without confirming that Delphi compiles it.
- Keep locals separate when they are `out`/`var` parameters, need initialization later, or must be declared earlier for scope or nested-routine capture.
- Put `begin` on the same line as `for ... do`, `if ... then`, and `else`, including after multiline conditions. Keep `else` on the same line as its preceding `end` (`end else if ... then begin`).
- Keep routine signatures on one line when they fit clearly; wrap only excessively long signatures.
- When a source change needs compile verification, ask the user to build the affected project(s) in the RAD Studio IDE. Command-line compiling is unsupported in this Delphi 13 installation. After the user confirms a successful build, run the relevant tests; do not claim a source change is compile-verified before then.
