# BrickStack2 plan

## Goal

Build a new, browser-based BrickStack application backed by a Delphi web server. Keep it alongside the existing VCL/MDI application so the desktop program continues to work while the web version is developed independently.

The target experience is the master-detail layout in [the design plan](../Misc/brickstack-design-plan.md), with [the bundled demo](../Misc/BrickStack-demo.html) as a visual and interaction reference. The demo is a prototype, not production frontend or server code; rebuild its UI as maintainable, separate assets.

## Project constraints

- Keep the backend in Delphi and prefer Delphi's built-in **WebBroker** framework.
- Use the installed Delphi 13 Community Edition as the initial development and compatibility baseline, subject to its current product terms and supported platforms. Record the exact compiler/build configuration and reproducible build instructions when bootstrapping the project.
- Use Delphi's included DUnit framework for automated tests; avoid requiring a paid or third-party test framework.
- The Windows SDK has been updated on the development machine. Verify and record the SDK selected by the Delphi 13 project when configuring and validating Windows builds.
- Keep application source, frontend source, and redistributable assets in the repository. Prefer built-in Delphi components and avoid third-party runtime/framework dependencies unless a demonstrated requirement justifies one.
- Review and record each dependency's license and any restrictions on redistribution. Apply the repository's MIT license to new BrickStack2 code unless the project owner chooses otherwise; check fonts, icons, images, and other assets separately.
- Treat the existing MDI app as read-only for this effort. Do not move, rename, or refactor its source as part of creating BrickStack2.
- Keep secrets, user credentials, and machine-specific database/configuration files out of source control.
- **Security is a core design requirement:** design the website and both services to be secure by default and protect user data, credentials, and server resources. Security must be considered in every feature and release decision, not treated as a final hardening task.

## Proposed architecture

```text
Browser
  ├── HTML, CSS, JavaScript and local static assets
  └── JSON requests to same-origin /api/... endpoints
          |
          v
Delphi WebBroker server
  ├── route/request handlers
  ├── application services (collection, search, sync, import/export)
  ├── repositories and database schema setup
  └── SQLite via FireDAC
```

- Serve the UI and API from the same origin initially. This avoids needing a separate frontend host and simplifies browser/API configuration.
- Keep HTTP handling thin: validate and translate requests, invoke services, and serialize responses. Keep SQL out of handlers and keep domain/service units independent of VCL forms and global form variables.
- Begin with SQLite and FireDAC, consistent with the existing application. Define a clear database path/configuration policy for development and deployment.
- Use JSON REST endpoints for browser operations. Return explicit HTTP error statuses and useful, non-sensitive error responses; do not expose database paths, credentials, or exception internals. Return a generic public error code that can be correlated with protected server-side logs.
- Store frontend files as normal readable project assets. Bundle and serve fonts and icons locally when their licenses permit; avoid runtime CDN requirements.
- Support a self-hosted server first. A desktop launcher or embedded browser can be considered later without coupling the server to VCL.

## Configuration and settings

**Decisions:** Use an INI file for machine/server-wide configuration. BrickStack 2 is a rewrite: do not migrate or remap v1 `TConfig` settings. Most v1 settings describe MDI window positions, frame-open state, column widths, and desktop interactions and have no need to carry forward. Put useful user-specific preferences in the v2 user/account data and ask before adding other persistent settings whose purpose is unclear. The compatibility priority is the existing SQLite database and its user/catalogue data, not the v1 INI file.

- The server INI is for operational settings such as the SQLite database path, bind address and ports, log/image-cache paths, and bounded service limits. Keep machine-specific INI files out of source control, validate configuration at startup, and document an appropriate protected location and filesystem permissions for the Windows service account.
- The administrator configuration page should expose the supported server configuration, a manual update action, and a way to request coordinated restart of both UI and backend servers. Define which settings may be edited live and which require restart; validate changes and persist them safely.
- **Decision: administrators may edit network binding/port settings in the UI.** Persist changes to the server INI and apply restart-required settings only through the coordinated restart flow. Validate before saving, write the INI atomically, and retain a documented recovery path: clearing/removing the INI restores safe defaults (including loopback-only binding). Show the effective and pending configuration clearly so a bad network change can be recovered directly on the host.
- **Decision: the admin page controls automated backup schedule and retention, offers a “run backup now” action, and displays backup status/last-run information.** Store supported backup settings in the server INI. Provide restore instructions/status, but do not make a destructive restore a one-click action without explicit confirmation, pre-restore backup, and recovery checks.
- **Decision: show service health and redacted recent operational events in the admin UI; keep full logs on the host.** Never include passwords, session/API tokens, or unnecessary personal collection data in UI-visible events or downloadable diagnostics.
- Server configuration, update, and restart operations are privileged control-plane actions, not ordinary collection APIs. Require administrator authorization, re-authentication or equivalent protection for sensitive actions, audit events, CSRF protection when cookie sessions are used, and safe handling of partial failure.
- The UI/backend processes must not provide an unauthenticated remote self-restart mechanism. In service deployment, route restart/update requests through a narrowly scoped local supervisor or Windows Service Control Manager integration that verifies the request and coordinates shutdown/startup. In development, provide equivalent controlled behavior for the two console hosts. Report progress/failure and retain a recoverable state if one process fails to restart.
- Treat secrets according to their use; do not assume every secret should be stored in the INI or database. User passwords are verified using a password hash and salt stored in the database; they are never recoverable or stored as plaintext. A hash is not suitable for credentials the server must later present to an external service.
- Before adding an external-service credential (for example, a Rebrickable API key or user token), decide whether it is server-wide or per-user and select storage accordingly. If the server must retrieve it, protect it at rest and restrict access; if stored in the database, keep any decryption key outside that database and protect it with an appropriate machine-level mechanism. Never commit or log credentials.
- Keep the configuration example limited to non-secret defaults/placeholders. Separate read-only application binaries from writable database, log, cache, and configuration locations as needed for service deployment.

## Security requirements and verification

BrickStack2 is intended to become a web-facing service. The design goal is to make the website and its services as secure as practical at every layer, with a secure-by-default posture. Follow current OWASP guidance, using the OWASP Application Security Verification Standard (ASVS) as the primary requirements and verification checklist and the OWASP Top 10 as a risk-awareness aid. Identify the applicable ASVS version and requirements when implementation begins; do not claim that checking the Top 10 alone proves the application secure.

Security work is part of normal development and release verification:

- Threat-model the browser, UI server, backend service, database, credentials, Global Admin/Server Admin/User Admin/User/Visitor permission boundaries, network exposure, and public-share links before their respective features are implemented. Record trust boundaries and abuse cases.
- For each feature, identify security requirements and add relevant tests with the implementation. Use DUnit for unit/integration checks and HTTP-level tests for actual request handling, authorization, configuration, and response behavior.
- If adding a second authentication factor, distinguish standards-based TOTP authenticator support from Google OAuth/OpenID Connect sign-in; they have different account, availability, and recovery requirements. Protect factor enrollment/recovery and add tests for verification, replay/expiry, lockout/rate limits, and recovery flows.
- Verify the default login and authentication flow, session handling, authorization on every request, collection ownership isolation, input validation, output encoding, CSRF protections where cookie-authenticated state changes are used, and safe CORS policy.
- Verify SQL is parameterized; secrets are stored and transported safely; passwords use a maintained, purpose-built password-hashing implementation (prefer Argon2id) with a unique cryptographically random salt and documented work factor; tokens and sessions have secure generation, storage, expiry, rotation, and revocation; and sensitive values never appear in logs or errors.
- Bootstrap the first administrator with the requested temporary `Admin` / `Admin` credentials only while no account exists. Expose this bootstrap only through loopback; require the administrator to choose a replacement password before granting normal application access. Store only the password hash, salt, and any algorithm/work-factor metadata needed for verification. Permanently disable the bootstrap credentials after the password change, and verify that neither password is stored or logged in plaintext.
- Test login and account endpoints for SQL injection and related input attacks; use parameterized SQL rather than relying on filtering or a login-page-only defense. Apply appropriate rate limiting and safe failure behavior to authentication attempts.
- By default, public self-registration is disabled. Only an authorized administrator can enable account creation; test both the disabled and enabled modes and ensure an enabled registration cannot select or obtain elevated roles.
- Enforce per-user collection isolation on the server for every read and write. A User can only view or modify their own private collection unless they explicitly publish it; Visitor access is limited to the public catalog and explicitly published read-only collections. Never trust UI hiding or client-supplied owner IDs as authorization.
- Global Admin may inspect and manage all user and server data. User Admin may perform only the specified account-management operations; Server Admin may perform only the specified server-management operations. Do not implicitly grant either scoped administrator access to users' private collection contents. Require authorization for each privileged action and record an audit event.
- Show users only a generic error code and safe message. Map codes to internal functions/locations and diagnostic details in protected server-side logs; logs must not be exposed through public responses or contain passwords, tokens, or other secrets. Test that malformed requests and internal exceptions do not leak SQL, paths, stack traces, configuration, or other system details.
- The admin UI may display service health and redacted recent operational events only; full diagnostic logs remain host-side and protected.
- Verify secure HTTP behavior, security headers, TLS/reverse-proxy assumptions, safe default bindings, request/body/resource limits, rate limits where appropriate, timeouts, and robust handling of malformed requests and backend outages.
- Test file import/export and image handling for path traversal, unsafe parsing, resource exhaustion, and unauthorized access. Test share links for scope, read-only enforcement, revocation, and resistance to guessing.
- Run dependency and license review, static/source review, automated security checks where practical, and a documented OWASP/ASVS release checklist. Use independent penetration testing before exposing a production deployment publicly.
- Treat security test failures as release blockers. Do not describe the application as completely or perfectly secure; document residual risks and deployment responsibilities.

The Phase 1 demo is local-only and uses dummy data, but still verify that the backend binds only to loopback, the browser cannot call the backend directly, backend failures are surfaced safely, and unexpected HTTP methods/paths are rejected. These checks are a foundation, not a production security sign-off.

## Performance requirements

Performance is a core product requirement and must influence architecture from the first implementation stage, not be deferred until after feature completion. Set and record measurable response-time and resource-use targets early using representative catalogue and collection sizes; do not guess at success based only on small development databases.

- Benchmark the important user journeys end to end, including server/API latency, database query time, and browser rendering. Keep repeatable test data and a baseline so later changes can be compared.
- Design queries for the actual UI: use appropriate indexes, bounded/paginated results for potentially large lists, and avoid N+1 queries or loading complete catalogues/collections when a view needs only a subset.
- Measure SQLite/FireDAC behavior under concurrent requests and writes. Use bounded connection/resource management and explicit transaction boundaries; do not assume the desktop connection-pool design is appropriate for a server.
- Keep expensive work such as imports, sync, and image processing out of request paths where practical. Use bounded background work and expose progress rather than allowing unbounded queues or request stalls.
- Optimize measured bottlenecks while preserving correctness, authorization, and maintainability. Add regression checks for critical queries and endpoints once representative targets are established.

## Data and account decisions

**Decision: use separate SQLite files for Brick catalog data and user data.** The catalog file is `DBase\rb.db` and contains imported Rebrickable catalogue tables; it is read-only during normal application requests. The BrickStack file is `DBase\BrickStack.db` and contains BS2 users, user settings, collections, set lists, owned sets, and parts. The backend owns the creation, validation, upgrade, and opening of both files at startup; the frontend has no database-bootstrap responsibility. Keep a single backend service and repository/service boundaries clear.

Start BS2 with a new, versioned BrickStack database schema; do not use an existing BS1 database as the startup database or alter it in place. Converting an existing BS1 database is a distinct, future migration step. That migration must preserve collection and catalogue data, be tested on a copy with backup/restore and safe rerun checks, and must not be coupled to normal first-run database creation.

**Decision: BrickStack 2 is multi-user from the start**, with separate collections and the following initial role definitions:

- **Global Admin:** full access to all application and server functions; bootstrap account initially uses `Admin` / `Admin` and must change its password before normal access.
- **Server Admin:** manages server configuration, network ports/binding, manual updates, backups, restart operations, and storage used/capacity.
- **User Admin:** manages user accounts (invite and delete users, reset TOTP, require a display-name change) and can see the total user count.
- **User:** creates and manages a private collection; marks owned sets/parts and organizes them within their own collection; may publish the collection and receive a shareable URL.
- **Visitor:** read-only access to the global Brick catalog; cannot create, edit, or manage any user's collection.

Enforce these permissions in the backend for every request, not only by hiding UI controls. Audit privileged account and server-management operations. A User Admin TOTP reset must invalidate the existing factor safely and require secure re-enrollment; deleting or disabling an account must revoke its sessions and tokens.

**Decision: Server Admin and User Admin permissions may be combined on one account.** Global Admin remains the all-permissions role. Only Global Admin may grant or revoke privileged admin permissions; User Admin invitations must not be able to create or elevate another administrator.

**Decision: a User may publish their collection at a share URL that anyone can open without signing in.** The URL may use a guessable identifier; secrecy of the URL is not security. On every request, the server must verify that the collection is currently published/enabled for public access, then serve only that collection's explicitly public data, read-only. The owner can revoke/unpublish it; revocation must take effect on subsequent requests. It grants no Visitor or account permissions and cannot reveal private collections.

The BS2 user-data schema is versioned independently from the Rebrickable catalogue and initialized transactionally. A missing schema-version table means version zero; run the supported version-zero migration rather than treating the file as corrupt. The migration must verify that the existing schema matches its known pre-version baseline, preserve its records, and update the version only after successful validation. Reject an incompatible schema without changing it; this is not a substitute for the separate BS1 conversion workflow. Do not repurpose the existing `BSDBVersions` table, which tracks catalogue import data, as the BS2 schema version. Cross-database catalog references should use stable catalogue identifiers; do not depend on foreign keys spanning SQLite files.

On first startup, if `rb.db` is absent, download the published `rb.db.gz` and `rb.db.sha256` assets, decompress to a staging file, verify that database file against the published SHA-256 sidecar, validate SQLite integrity and required catalogue tables, then move the validated database into place. If an existing catalogue fails validation, stop with an explicit startup error; do not overwrite it or silently fetch a replacement. Catalogue refresh/update is a separate operation.

The catalog database may be refreshed wholesale independently of user data. Download/build a candidate catalog separately, validate its schema and required keys, then activate it only when complete; do not overwrite the last known-good catalog with a partial or incompatible update. Coordinate replacement with active connections. A catalog refresh must not rewrite or discard user-owned collection rows, and the UI/API should handle a catalog item missing from a later catalog version without losing the user's record.

In-place schema continuity does not automatically make simultaneous v1 and BrickStack2 writers safe: the existing desktop app has no account context and cannot assign ownership to new rows. Do not claim concurrent backward compatibility without a tested ownership strategy; document whether running both versions against the same database is unsupported.

Passwords must be securely hashed; sessions/tokens must be revocable; public share URLs must be scoped and read-only. Do not rely on an unguessable URL as the authorization control: the server must check the collection's current public-sharing permission on every request. Every endpoint must enforce role and collection ownership on the server, independently of which controls the UI displays.

**Decision: support TOTP authenticator apps as the second factor.** TOTP is mandatory for Global Admin, Server Admin, and User Admin accounts, and optional but recommended for Users. This uses the standard authenticator-compatible TOTP protocol and does not depend on calling Google's API. Protect enrolled TOTP secrets at rest; provide secure enrollment confirmation, recovery codes, factor reset/recovery, rate limiting, and tests for code expiry/replay and account-recovery behavior.

**Account policy decisions:** Self-registration is disabled by default and can only be enabled by an authorized administrator. An enabled registration grants only the configured non-admin role. Users can modify only their own collection. Global Admin may inspect/manage all functions; User Admin receives only the explicitly defined user-management permissions; Server Admin receives only the explicitly defined server-management permissions. Public collection URLs are read-only and must never grant access to private collections or editing rights.

**Admin UI organization decision:** Provide a dedicated Admin > Users area for invites/account provisioning, role assignment, deletion, TOTP reset, display-name-change enforcement, and total user count. Provide a separate Server Configuration/Operations area for Server Admin permissions, including self-registration policy (enabled/disabled and permitted default role), network settings, updates, backups, storage, and coordinated restart.

## Decisions to confirm before implementation

These are intentionally open questions to review together; they do not block architecture research or the initial project bootstrap.

- **First-release network exposure:** Should the default be localhost-only, with LAN access as an explicit configuration option, or should LAN access be a supported first-run mode? Public exposure should require a reverse proxy/TLS setup either way.
- **Desktop debug host:** Should the VCL development host only start/stop the server and open the system browser, or should an embedded browser be an initial requirement?
- **Rebrickable credentials:** Should each user configure their own API key and account token, or should the server administrator provide a shared API key while users provide their own account tokens? Credentials must remain server-side.

## Delivery phases

### 1. Bootstrap the two-service web slice

**Goal:** Finish Phase 1 with a basic BrickStack2 page visible in a browser. A Delphi WebBroker UI server serves the page and makes a server-side request to a separate Delphi WebBroker backend service. The backend returns dummy JSON; the UI displays it. This proves the browser-to-UI-server-to-backend-server path before connecting any real data.

**Status: Phase 1 complete.** The user confirmed that the relocated UI and backend projects compiled and ran, the browser displayed the demo page, and the DUnit runner reported 1 passing test. The user also confirmed the UI displays its backend-unavailable message when the backend cannot be reached. After the project move, the user verified the UI health endpoint, an unknown route returning `not_found`, and `POST /health` returning the expected method-not-allowed response. Before implementing feature endpoints, establish representative baseline data and draft measurable performance targets.

- Keep the Delphi group project (`.groupproj`) at the `BrickStack2\` root. Put the backend, UI, and test Delphi project files under `Src\Backend\`, `Src\UI\`, and `Src\Tests\` respectively; keep shared source under `Src\` and project-specific source/assets with their owning area.
- Bind both development services to loopback by default, on documented separate ports. Provide a convenient way to start them and open the UI in a browser.
- Have the UI server fetch the dummy data from the backend. The browser calls only the UI server; it must not call the backend directly. Show a clear error in the page if the backend is unavailable rather than silently substituting dummy data in the UI server.
- Add health endpoints for each service, DUnit coverage for the dummy JSON, and HTTP smoke checks for the service endpoints and server-to-server request.
- Keep the completed demo's loopback binding, same-origin browser access, method/path rejection, and safe backend-error behavior in the repeatable smoke/security checks.
- Configure build outputs so neither service overwrites the existing application's outputs or the other service's outputs.
- Confirm both projects build with Delphi 13 Community Edition and the installed Windows SDK, and the DUnit suite runs.
- **Phase 1 does not connect to SQLite, alter the existing database, or implement user-management schema.** Those start with the real-data work in Phase 2.

### 2. Build a read-only vertical slice

**Status: read-only catalog search and set-inventory browsing implemented and verified on 2026-10-11.** The backend startup path ensures `rb.db` is checksum-verified and valid, and initializes or upgrades `BrickStack.db` independently. Both files were confirmed in `Bin\Win64\Debug\DBase`. The catalog passes SQLite `quick_check`; it contains `sets` (28,449 rows), `parts` (64,826), `themes` (496), and `colors` (275), with indexes on set theme/year, part category/material, and theme parent. Direct inspection of `rb.db` confirmed the inventory schema: `inventories(id, version, set_num)` with unique index `(set_num, version)`; `inventory_parts(inventory_id, part_num, color_id, quantity, is_spare, img_url)` indexed by `inventory_id`; related indexes include `inventory_parts(part_num,color_id)`. The typed read-only repository implements parameterized set/part search, filters, stable keyset pagination, detail/lookup/summary reads, and latest-or-explicit-version inventory paging by `(part_num,color_id,is_spare)`. The API exposes `/api/catalog/sets/{setNumber}/inventory`; the browser supports theme/year set filtering and category/color part filtering; the set-detail dialog loads and pages through colored part quantities, including spare quantities. Verification on 2026-10-11: all 11 DUnit tests passed, HTTP smoke checks passed, and browser checks confirmed catalog totals, set/part search, theme/year filtering, set details, inventory version 1, 50 initial entries, and a subsequent page with 65 cumulative entries. Graceful console shutdown is requested with Ctrl+Break (console close is also handled).

**UI scope clarification:** the current browser vertical slice now has distinct Overview, Sets, and Parts navigation. The overview displays real Rebrickable catalog totals; Sets and Parts show the corresponding real catalog search/filter interfaces without repeating those totals. These are not mocked search results, but the Overview is not yet the planned collection-progress dashboard, and the design plan's collection lists/detail panes, minifigs, editing, and administration screens remain future work.

**Authentication and ordinary-user provisioning status (verified 2026-11-01):** First startup creates the loopback-restricted `Admin` / `Admin` Global Admin only when the user table is empty; password replacement disables that bootstrap path. Passwords use Windows CNG PBKDF2-HMAC-SHA256 (600,000 iterations, random 16-byte salt). Login, logout, and session lookup use opaque 12-hour cookies whose token hashes are persisted; failed logins are throttled per account, and active lockouts are not extended by further attempts. State-changing browser requests require the same-origin request header. A Global Admin can list accounts and provision ordinary Users with a generated 256-bit temporary password; it is shown once, only in the authenticated create response, and must be replaced before sign-in. The version-three schema adds case-insensitive username uniqueness. Admin roles cannot be assigned through this provisioning flow.

Verification: the user confirmed clean Delphi IDE builds; all 18 DUnit tests passed, covering bootstrap/password hashing, session lifecycle and expiry, login lockout, version-one-to-three migration, temporary-password replacement, and duplicate usernames. `Test-BrickStack2.ps1` passed against the rebuilt services. The account UI was exercised with mocked API responses; a full authenticated create-user browser journey was not run because no test admin credentials were available. The earlier bootstrap `forbidden` diagnostic issue is resolved and included in the live smoke checks.

**TOTP milestone (implemented and verified 2026-11-06):** schema version four adds factor-enrollment and hashed recovery-code storage. Authenticator-compatible TOTP uses a Windows DPAPI-protected secret, a password-plus-code login, one-use recovery codes, replay rejection, and the existing per-account login lockout. Global Admin account-management routes require an enrolled factor; ordinary Users may enroll optionally. Enrollment has a ten-minute confirmation window and returns ten recovery codes once. The browser supports manual authenticator setup and login recovery. DPAPI data is bound to the Windows identity running the backend. The user-admin factor-reset workflow remains part of the future dedicated User Admin area. The user confirmed all Delphi IDE builds succeeded and all 21 DUnit tests passed.

**Collection ownership foundation (implemented and verified 2026-11-07):** `GET /api/collections`, `GET /api/collections/{id}`, and `POST /api/collections` require an authenticated session and same-origin protection for creation. The owner is taken from the session, never from request data; per-user list and ID lookups are owner-filtered, and cross-owner IDs return the same not-found result as missing IDs. Collections are private by default, including for Global Admin. All three Delphi IDE builds succeeded; all 25 DUnit tests passed; the HTTP smoke checks passed, including unauthenticated collection access and UI proxy behavior. Unit tests cover owner isolation, ID manipulation, duplicate names, and validation.

**Collection renaming (implemented and verified 2026-11-07):** An owner can rename a collection with `PUT /api/collections/{id}`. The backend derives the owner from the session, accepts only the name field, and preserves private/public state. Other users receive the same not-found result as for a missing ID. Duplicate names and invalid names are rejected. The user confirmed all Delphi IDE builds succeeded; all 27 DUnit tests and live HTTP smoke checks passed. DUnit tests cover ownership and validation; smoke checks cover CSRF/authentication barriers. Collection deletion is deliberately deferred; deletion semantics for nested set and parts data need separate agreement.

**Authenticated collection HTTP verification (implemented and verified 2026-11-07):** `Test-BrickStack2CollectionAuth.ps1` creates an isolated temporary backend database, seeds two ordinary test accounts, logs them in through the real authentication endpoint to establish independent sessions, and tests list/detail/rename ownership through both the UI proxy and backend. The script refuses to run if the service ports are already in use and removes its isolated data afterward. The authenticated ownership checks passed.

**Set-list and set-item APIs (implemented and verified 2026-11-07):** Added owner-scoped set-list listing/creation/read/update/removal and set-entry listing/creation/read/update/removal. Ownership is checked through the collection owner for each query and write. New set entries must refer to a set in the local catalog; an entry represents one copy and stores built/spare-parts flags and notes. Removing a set list cascades through its sets and saved inventory rows. The user confirmed clean RAD Studio builds for the backend and tests projects; all 31 DUnit tests passed. Authenticated integration tests passed through both the UI proxy and backend, including cross-owner denial and CSRF checks. General HTTP smoke checks passed.

**Next authorization milestone:** add loose-part list and quantity operations using the same owner-boundary enforcement. Keep Server Admin and User Admin roles unavailable until their permission boundaries are implemented.

- At backend startup, create `DBase` if needed; ensure `rb.db` exists by downloading the published gzip and SHA-256 assets when absent, decompressing to a staging file, verifying the database against the checksum sidecar, validating integrity/schema, and installing it atomically. Never replace an invalid existing catalogue automatically.
- Independently create or open `BrickStack.db`, treating a missing schema-version table as version zero and applying the supported version-zero migration transactionally. Keep schema creation and updates idempotent; test clean creation, repeated startup, current-version opening, preservation of supported pre-versioned data, and safe rejection of incompatible schemas.
- Keep the BS1 database untouched during normal startup. Plan the one-time BS1 conversion as separate future work; it must work from a backup/copy and preserve collection and catalogue data.
- Add catalog and user-data repositories with parameterized queries and managed connection lifetimes appropriate for concurrent web requests. The initial Rebrickable catalog repository is implemented using per-operation read-only FireDAC connections, bounded keyset-paginated set/part searches, and small lookup queries. Attach the catalog database for read joins where useful; keep catalog access read-only during normal requests and collection writes confined to the user-data database.
- **Complete:** implement the one-time loopback-only `Admin` / `Admin` bootstrap and mandatory password replacement before normal access; test bootstrap availability, password-change enforcement, bootstrap disablement, and password-hash storage and verification.
- Expose read endpoints for overview totals, set lists, and sets in a list.
- Render the corresponding overview, list pane, and set detail using the reference layout.
- Add focused DUnit tests for query results, endpoint response shape, invalid input, and database errors.
- Add OWASP/ASVS-driven tests for unauthenticated and cross-collection reads, input handling, and data/error disclosure before exposing the read endpoints beyond localhost.
- Verify generic public error codes against protected internal diagnostics: no SQL text, filesystem paths, stack traces, configuration, or secrets may leak to clients.
- Measure the read-only journeys against representative data; tune query/index/pagination design and record the baseline and targets.

### 3. Add collection operations

**Progress:** private collection listing, detail reads, creation, owner-only renaming, set-list operations, and set-entry operations are implemented and verified. Collection deletion and publication remain deferred.

- Implement and validate edits through explicit API operations: set/list creation and updates, quantities, notes, and removal.
- Add server-side input validation, authorization checks, transactions where needed, and tests for failure and concurrency cases.
- Add request-level security tests for authentication, role enforcement, ownership checks, CSRF protections when applicable, and attempts to bypass UI restrictions.
- Test that users cannot enumerate, view, or modify another user's records by manipulating IDs or request payloads; test admin inspection authorization, read-only behavior, and audit logging.
- Test schema setup against a copy of an existing BrickStack database, verifying existing catalogue and collection data is preserved, ownership is assigned correctly, rerunning setup is safe, and failures do not leave partial schema changes. Verify every catalog row and stable identifier is retained in the catalog file and define how user-data and catalog backups are restored together (or how the catalog is rebuilt).

### 4. Add catalog and integrations

- Add search and set/part/minifig detail views using the available catalogue database.
- Implement import/export and Rebrickable sync behind Delphi services.
- Keep API keys on the server. Add bounded download queues, backoff, and local image caching before serving images to browsers.

### 5. Complete accounts, roles, and sharing

- Complete account workflows and role enforcement across every relevant endpoint, not only UI visibility. The account and ownership schema are already present from the initial release.
- Test that public account creation is disabled by default, only an administrator can enable it, and new accounts cannot choose an elevated role.
- Provide admins with audited, privileged inspection of user accounts and stored collection data without implicitly granting cross-user edit permission.
- Add the dedicated User Admin workflows for invitations, deletion, TOTP reset, forced display-name change, and user-count visibility; enforce the permission boundary against Server Admin.
- Add owner-controlled public collection publishing and read-only share routes available without sign-in. Do not rely on an unguessable identifier: test that unpublished collections are denied even when their URL is known, permission is checked on every request, revocation takes effect, only the explicitly public collection data is exposed, and mutations/unrelated collection disclosure are prevented. Public URLs do not grant account/Visitor access.
- Verify account recovery, session/token lifecycle, credential handling, privilege boundaries, and share-link abuse cases against applicable OWASP ASVS requirements.

### 6. Packaging and deployment

- Document Windows self-hosting, configuration, database backups, upgrades, and network exposure.
- Keep default binding local-only; require deliberate configuration for LAN/public access and explain reverse-proxy/TLS expectations.
- Re-run the performance checks with representative data and documented hardware/configuration; address regressions against the agreed targets before release.
- Complete the applicable OWASP ASVS release checklist, resolve high-risk security findings, and perform an independent security assessment before enabling public production access.
- Recheck current Community Edition eligibility, platform support, and any deployment requirements before release.

### 7. Database updates and catalog refresh

- Separate BrickStack application-schema updates (tables, columns, indexes) from imported catalog-data refreshes; each has its own validation, failure handling, and progress reporting.
- Back up the user database before any schema/data update that could affect user-owned records. Validate prerequisites and available disk space, make safe operations transactional, and leave a recoverable prior state on failure.
- Refresh the separate catalog data without corrupting or partially replacing the last known-good catalog. Test interrupted downloads/imports, incompatible schemas/keys, rollback/retry, open-connection handling, and catalog/user-data compatibility.
- Back up user data and define whether the catalog file is included in coordinated backups or reproducibly rebuilt. Do not require cross-file write transactions for ordinary collection operations.
- Expose update status and errors safely to the UI; keep long imports outside request threads and bound their resource use.

### 8. Automated backups

- Provide configurable automatic backups of user-owned data with documented schedule, retention, storage location, and disk-space limits.
- Let administrators configure schedule and retention, request an immediate backup, and inspect last-run status from the admin UI; persist supported settings in the server INI.
- Use a SQLite-consistent online backup mechanism rather than copying a live database file naively; include the user database and either the matching catalog file or reliable instructions to rebuild it.
- Protect backups because they contain personal collection data and password hashes. Do not log secrets or include server credentials unless separately protected and necessary.
- Verify backup integrity and provide a documented restore procedure. Test restoring and starting the application from a backup, not only creating backup files.

### 9. Application auto-updater

- Add an updater only after installation/deployment and backup/restore behavior are established.
- Verify update authenticity and integrity before installation; use a trusted signing/release process and protect against downgrade or partial-update failures.
- Stop or coordinate services safely, preserve configuration and user data, take/verify a pre-update backup when needed, install atomically where practical, and support recovery to the prior working version.
- Require explicit administrator authorization and document whether updates are automatic, user-approved, or admin-triggered; do not silently execute untrusted update content.

### 10. Convert an existing BS1 database (future, separate step)

- Provide an explicit conversion workflow that accepts a BS1 database as input; normal BS2 startup must never modify or silently adopt it.
- Back up the source and test conversion on a copy. Split imported Rebrickable catalogue data into `rb.db` and BrickStack-owned collection data into `BrickStack.db`, preserving set-list relationships, individual set state, custom tags, inventory, and user data.
- Map the existing local collection to an initial BS2 owner/account according to the account-bootstrap policy; report records that cannot be mapped rather than dropping them.
- Validate source/target integrity, row counts and relationships; make conversion restartable or safely repeatable, and document rollback and backup/restore.
- Do not claim concurrent BS1/BS2 writing against the same database is supported unless ownership and compatibility behavior are explicitly implemented and tested.

## Initial API sketch

Use **purpose-built JSON REST resources and search endpoints**: fixed, documented response shapes with a small set of validated query parameters. Do not expose arbitrary SQL or adopt OData for the initial catalog API. OData's open-ended filters, projections, expansions, and ordering add parser, authorization, query-planning, and compatibility surface without matching the UI's known page needs. Avoid hard-coding a separate route for every filter combination; encode supported filters as query parameters and whitelist them server-side.

Serve browser requests same-origin through the UI server, which proxies only the intended API paths to the backend. Return the page shell and local assets immediately, then fetch independent panel data asynchronously: render the overview first, and load search results, selected details, or inventories only when needed. Give every list/search a bounded page size and stable pagination (prefer keyset/cursor pagination for large result sets); return only fields required by that view. Use explicit loading, empty, and error states rather than holding the whole page until all data is available.

Initial read-only catalog endpoints, based on the confirmed Rebrickable schema in `rb.db`:

- `GET /api/catalog/summary`
- `GET /api/catalog/sets?q=&themeId=&year=&pageSize=&cursor=`
- `GET /api/catalog/sets/{setNumber}`
- `GET /api/catalog/sets/{setNumber}/inventory?pageSize=&version=&cursor=`
- `GET /api/catalog/parts?q=&categoryId=&colorId=&pageSize=&cursor=`
- `GET /api/catalog/parts/{partNumber}`
- `GET /api/catalog/themes`, `/api/catalog/colors`, and
  `/api/catalog/part-categories` for filter lookup lists.

Set and part search, filter lookups, detail reads, and set inventory paging
are connected to the browser through the allowlisted same-origin proxy.
Inventory pagination uses the selected inventory version and a composite
part/color/spare cursor.

Search/detail endpoints should use parameterized SQL and fixed allowed sort/filter fields; cap query length, page size, and response size. Add account/collection reads, writes, import, sync, and share endpoints separately alongside their authorization and tests.

## UI direction

- Use the chosen 1b master-detail layout: navigation rail, list pane, and detail pane.
- Start with responsive overview, set lists, and set detail; progressively implement parts, minifigs, search, and settings.
- Keep theme and visual tokens in CSS variables. Treat the demo's placeholder data and UI-only interactions as non-production.
- Ensure core navigation and collection operations remain usable on narrow/mobile screens.

## Definition of a first usable milestone

BrickStack2 is independently buildable with Delphi 13 Community Edition and the configured Windows SDK, and its DUnit suite runs. The Phase 1 milestone is the UI server serving a browser page that displays dummy data fetched server-to-server from the separate backend. By the end of Phase 2, the backend creates or opens its fresh, versioned `BrickStack.db`, ensures a verified `rb.db` is available, and serves real overview/list/set data through read-only API endpoints with multi-user collection ownership enforced. The existing BrickStack project still opens and builds independently. Converting existing BS1 data is a separate future migration milestone.

## Source references

- [Design plan](../Misc/brickstack-design-plan.md)
- [Bundled UI demo](../Misc/BrickStack-demo.html)
- [Existing database creation and version scripts](../Src/Scripts/UBSSQL.pas)
- [Existing main VCL form](../Src/Frames/UFrmMain.pas)
