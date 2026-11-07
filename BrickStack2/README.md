# BrickStack2

BrickStack2 is the separate WebBroker-based web application under development.
The existing BrickStack desktop application is not changed by this project.
Project goals and phases are documented in `.docs\PLAN.md`; add
project and IDE-specific guidance is in `.docs\context.md`.

## Current UI scope

The browser navigation separates **Overview**, **Sets**, and **Parts**.
Overview currently shows real Rebrickable catalog totals; Sets and Parts show
their respective search/filter panels without repeating those totals. The
catalog search, set/part details, and set inventory are connected to the local
read-only `rb.db` API, rather than placeholder results.

This is still an early vertical slice, not the complete 1b collection UI in
`.docs\PLAN.md` and `Misc\brickstack-design-plan.md`. The planned overview of a
user's collection, set-list progress, incomplete sets, list/detail panes,
minifigs, collection editing, and user/operations screens have not been built.
The authenticated collection API is being built independently of those browser
screens.

## Phase 1: WebBroker foundation

BrickStack2 runs two Delphi console services on loopback:

- UI server: <http://127.0.0.1:8080>
- Backend server: <http://127.0.0.1:8081>

The UI server serves the page and local CSS/JavaScript assets. The browser
loads catalog totals, set/part search results, and details asynchronously from
same-origin `/api/catalog/...` routes; the UI server forwards only allowlisted
catalog requests to the backend. The earlier `/api/demo` endpoint remains for
smoke-test compatibility but is no longer used by the page.

## Phase 2: backend database bootstrap

Before the backend starts listening, it initializes two separate databases
under `DBase\` beside the backend executable:

- `BrickStack.db` is created from the versioned BS2 schema when absent or
  empty. A missing schema-version table means version zero; startup applies the
  supported version-zero bootstrap or a transactional version-one-to-two
  migration. It holds
  BrickStack-owned users, settings, collections, set lists, sets, and parts.
  Existing current-version databases are opened and checked. An incompatible
  unversioned schema stops startup without being modified.
- `rb.db` holds the Rebrickable catalogue. If it is missing, the backend
  downloads `rb.db.gz` and `rb.db.sha256` from the published database release,
  decompresses to a staging database, verifies its SHA-256 against the
  sidecar, and validates it before installation. An existing invalid
  catalogue is not replaced automatically.

Database setup is backend-only; the browser and UI server do not create or
update either database. Normal first-run setup never modifies a BS1 database.
Converting an existing BS1 database is planned as a separate migration step.
For now the catalogue bootstrap needs Internet access on the first backend
startup.

The Delphi group project is in the BrickStack2 root and includes all three
projects. Open `BrickStack2.groupproj` in the Delphi IDE to build them together,
or open an individual Delphi 13 Win64 project in Debug configuration:

- `Src\UI\BrickStack2UI.dproj`
- `Src\Backend\BrickStack2Backend.dproj`
- `Src\Tests\BrickStack2Tests.dproj`

Source organization:

- `Src\` contains source shared by the services.
- `Src\Backend\` contains backend-only source.
- `Src\Backend\UBSRebrickableCatalogRepository.pas` provides typed, read-only
  access to Rebrickable sets, parts, and filter lookup tables. It uses
  parameterized FireDAC queries, a read-only SQLite connection, and bounded
  keyset-paginated search results.
- `GET /api/catalog/summary` returns actual set, part, and theme counts.
- `GET /api/catalog/sets?q=&themeId=&year=&pageSize=&cursor=` and
  `GET /api/catalog/parts?q=&categoryId=&colorId=&pageSize=&cursor=` provide
  fixed JSON search results. Page size is limited to 1-100, with a default of
  25 and keyset cursors. Singular set/part routes return details; themes,
  colors, and part categories are served as lookup lists. The browser exposes
  theme and year filters for sets and category and color filters for parts.
  The UI server only proxies these allowlisted catalog routes and `/api/demo`
  to the backend.
- `GET /api/catalog/sets/{setNumber}/inventory?pageSize=&version=&cursor=`
  returns a bounded, color-aware parts inventory. If `version` is omitted, the
  latest available inventory version is selected; pagination remains anchored
  to that version. Set details can load inventory pages on demand.
- First startup creates the temporary `Admin` / `Admin` Global Admin only if
  the BrickStack user table is empty. The same-origin UI exposes a loopback-only
  password replacement form at first run; the temporary credential is stored
  only as a salted PBKDF2-HMAC-SHA256 hash (600,000 iterations), and a successful
  replacement permanently disables this bootstrap route.
- Existing enabled users whose initial password change is complete can sign in
  through the top-right profile control. `POST /api/auth/login` issues an
  HttpOnly, SameSite=Strict opaque cookie; only its SHA-256 hash is persisted
  in `BSSessions`, where sessions have a 12-hour absolute expiry. Accounts
  with TOTP enabled must also supply an authenticator or unused recovery code.
  Global Admin tools remain unavailable until TOTP enrollment is complete;
  ordinary Users may enroll optionally. TOTP secrets are protected with Windows
  DPAPI, accepted codes cannot be replayed, and recovery codes are stored only
  as hashes and consumed on use. Enrollment returns ten recovery codes once.
  The BrickStack user database schema is version four; existing version-three
  databases are migrated transactionally to add factor and recovery-code
  storage.
  `GET /api/auth/session` returns the current profile, and
  `POST /api/auth/logout` revokes the session and clears the cookie. Five
  failed password or factor attempts in a 15-minute window lock that account
  for 15 minutes; attempts during an active lockout do not extend it. Auth
  routes are loopback-only and state-changing browser requests require the
  same-origin custom request header. DPAPI-protected factors are tied to the
  Windows identity used by the backend, which must be preserved for service
  operation and backup recovery.
- Signed-in users can list their own collections with `GET /api/collections`,
  read one with `GET /api/collections/{id}`, and create a private collection
  with `POST /api/collections`. Owners can rename a collection with
  `PUT /api/collections/{id}` using a JSON `name` field. Ownership is always
  derived from the session; supplied owner IDs and other rename fields are
  rejected, and another user's collection is indistinguishable from a missing
  collection. Even Global Admin collection routes are owner-scoped. Collection
  deletion and public sharing are not implemented yet.
- Collection owners can list and create set lists with `GET` and `POST` at
  `/api/collections/{collectionId}/set-lists`, read/update/delete a list with
  `GET`, `PUT`, and `DELETE` at `/api/set-lists/{setListId}`, and list or add
  set entries with `GET` and `POST` at `/api/set-lists/{setListId}/sets`. Set
  entries can be read, updated, or removed with `GET`, `PUT`, and `DELETE` at
  `/api/collection-sets/{setId}`. Every operation derives ownership through the
  authenticated session and returns not-found for another user's IDs. Added
  sets must exist in the local Rebrickable catalog. A set entry represents one
  copy; add another entry for another copy. Updating a set entry changes its
  built/spare-parts flags and notes, not its catalog set number. Removing a set
  list cascades to its sets and saved inventory rows. Collection deletion,
  public sharing, and loose-part list operations remain unimplemented.
- A signed-in Global Admin can provision ordinary User accounts from the
  profile dialog. The server generates a 256-bit temporary password, returns it
  only in the creation response, stores only its salted password hash, and
  marks the account as requiring password replacement. The new user uses the
  invitation form and `POST /api/auth/password` before signing in.
  `GET /api/admin/users` lists accounts; `POST /api/admin/users` provisions an
  ordinary User. The account list omits password data. Account management is
  loopback-only and protected by an enrolled Global Admin session; users
  cannot select a role, and this flow cannot grant admin roles. Server Admin
  and User Admin provisioning remains deferred until role-specific
  authorization is implemented.
- `Src\UI\` contains UI-server source and its browser assets in `Src\UI\Web\`.
- `Src\Tests\` contains test-only source, including fixture-backed catalog
  repository tests.

Build outputs go to `Bin\Win64\Debug\`; compiler units go to distinct
`Bin\Dcu\...` subfolders per project.

Run `Bin\Win64\Debug\BrickStack2Tests.exe` to execute the DUnit tests. Run
`.\Test-BrickStack2.ps1` after starting both services for HTTP integration
smoke checks covering database presence, signed-out state, authentication,
collection route access and CSRF checks, catalog totals, search, detail reads,
pagination, validation, and proxy allowlisting. To start both services and open
the page in your browser, run the following from the BrickStack2 folder:

```powershell
powershell -ExecutionPolicy Bypass -File .\Start-BrickStack2.ps1
```

Run `.\Test-BrickStack2CollectionAuth.ps1` after building all three projects to
exercise authenticated collection isolation through both HTTP services. It
starts a temporary backend database under the Debug output directory with a
hard-linked catalog database, seeds two ordinary test accounts, logs in through
the authentication API to create separate sessions, and verifies
collection, set-list, and set-item list/detail/create/update/remove ownership.
It requires ports 8080 and 8081 to be free and stops only the service processes
it starts; its temporary database directory is removed afterward.

The launcher opens a separate console window for each service. Press Ctrl+Break
in a service's own window to request an orderly stop of that service; closing
the console window also requests shutdown. Stopping the UI does not stop the
backend, and vice versa. Alternatively, start
`Bin\Win64\Debug\BrickStack2Backend.exe` and
`Bin\Win64\Debug\BrickStack2UI.exe` in separate console windows, then open
<http://127.0.0.1:8080>.

The browser page shows an explicit error if the backend is stopped. Both
services bind only to `127.0.0.1` during this development phase. Delphi 13
Community Edition reports that command-line compiling is unsupported in this
installation, so build projects from the IDE.

The Win64 backend and test projects copy Delphi's `bin64\sqlite3.dll` beside
their output executable during the IDE build. Review the SQLite library's
redistribution terms before packaging it outside the development environment.

Both console services print timestamped lifecycle and request messages. The
backend reports database checks, download/decompression/checksum/validation
steps, and startup failures; the UI server reports served assets, browser
requests, backend forwarding results, and listener shutdown.
