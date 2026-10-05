# BrickStack2

BrickStack2 is the separate WebBroker-based web application under development.
The existing BrickStack desktop application is not changed by this project.
Project goals and phases are documented in `.docs\PLAN.md`; add
project and IDE-specific guidance is in `.docs\context.md`.

## Phase 1: run the browser demo

Phase 1 runs two Delphi console services on loopback:

- UI server: <http://127.0.0.1:8080>
- Backend server: <http://127.0.0.1:8081>

The page and its local CSS/JavaScript assets are served by the UI server. The
browser requests `/api/demo` from that same origin; the UI server fetches the
dummy JSON from the backend and returns it. The backend does not access SQLite
in this phase.

The Delphi group project is in the BrickStack2 root and includes all three
projects. Open `BrickStack2.groupproj` in the Delphi IDE to build them together,
or open an individual Delphi 13 Win64 project in Debug configuration:

- `Src\UI\BrickStack2UI.dproj`
- `Src\Backend\BrickStack2Backend.dproj`
- `Src\Tests\BrickStack2Tests.dproj`

Source organization:

- `Src\` contains source shared by the services.
- `Src\Backend\` contains backend-only source.
- `Src\UI\` contains UI-server source and its browser assets in `Src\UI\Web\`.
- `Src\Tests\` contains test-only source.

Build outputs go to `Bin\Win64\Debug\`; compiler units go to distinct
`Bin\Dcu\...` subfolders per project.

Run `Bin\Win64\Debug\BrickStack2Tests.exe` to execute the DUnit tests. Run
`.\Test-BrickStack2.ps1` after starting both services for HTTP integration
smoke checks. Run the following from the BrickStack2 folder to start both
services and open the page in your browser:

```powershell
powershell -ExecutionPolicy Bypass -File .\Start-BrickStack2.ps1
```

The launcher opens a separate console window for each service. Press Ctrl+C
in a service's own window to stop just that service; stopping the UI does not
stop the backend, and vice versa. Alternatively, start
`Bin\Win64\Debug\BrickStack2Backend.exe` and
`Bin\Win64\Debug\BrickStack2UI.exe` in separate console windows, then open
<http://127.0.0.1:8080>.

The browser page shows an explicit error if the backend is stopped. Both
services bind only to `127.0.0.1` during this development phase. Delphi 13
Community Edition reports that command-line compiling is unsupported in this
installation, so build projects from the IDE.
