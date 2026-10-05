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

## Security requirements and verification

BrickStack2 is intended to become a web-facing service. The design goal is to make the website and its services as secure as practical at every layer, with a secure-by-default posture. Follow current OWASP guidance, using the OWASP Application Security Verification Standard (ASVS) as the primary requirements and verification checklist and the OWASP Top 10 as a risk-awareness aid. Identify the applicable ASVS version and requirements when implementation begins; do not claim that checking the Top 10 alone proves the application secure.

Security work is part of normal development and release verification:

- Threat-model the browser, UI server, backend service, database, credentials, admin/member/viewer boundaries, network exposure, and public-share links before their respective features are implemented. Record trust boundaries and abuse cases.
- For each feature, identify security requirements and add relevant tests with the implementation. Use DUnit for unit/integration checks and HTTP-level tests for actual request handling, authorization, configuration, and response behavior.
- Verify the default login and authentication flow, session handling, authorization on every request, collection ownership isolation, input validation, output encoding, CSRF protections where cookie-authenticated state changes are used, and safe CORS policy.
- Verify SQL is parameterized; secrets are stored and transported safely; passwords use an appropriate password-hashing scheme; tokens and sessions have secure generation, storage, expiry, rotation, and revocation; and sensitive values never appear in logs or errors.
- Test login and account endpoints for SQL injection and related input attacks; use parameterized SQL rather than relying on filtering or a login-page-only defense. Apply appropriate rate limiting and safe failure behavior to authentication attempts.
- By default, public self-registration is disabled. Only an administrator can enable account creation; test both the disabled and enabled modes and ensure an enabled registration cannot select or obtain elevated roles.
- Enforce per-user collection isolation on the server for every read and write. A signed-in user can only view or modify their own collection (or explicitly authorized viewer scope); never trust UI hiding or client-supplied owner IDs as authorization.
- Administrators may inspect user accounts and their stored collection data through explicit privileged, read-only access. Require authorization for each inspection, record an audit event, and do not let inspection implicitly grant permission to modify another user's collection. Define any administrative account-management actions separately.
- Show users only a generic error code and safe message. Map codes to internal functions/locations and diagnostic details in protected server-side logs; logs must not be exposed through public responses or contain passwords, tokens, or other secrets. Test that malformed requests and internal exceptions do not leak SQL, paths, stack traces, configuration, or other system details.
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

The existing SQLite database contains BrickStack set lists, sets, custom tags, set inventory, and imported catalogue data. BrickStack 2 will use this same database file and extend its schema in place with the additional user-management tables and columns it needs. It will not create a separate v2 database or copy the existing collection into a new database.

**Decision: BrickStack 2 is multi-user from the start**, with separate user collections and admin, member, and viewer roles, as described in the design plan. Collection ownership and authorization belong in the initial schema and API; do not ship a shared single-user collection and retrofit these boundaries later.

The existing database has no account or collection-owner model. Schema setup must preserve its existing tables and data, add the account/ownership tables and columns, and associate the existing local collection with the initial administrator. Preserve individual set entries and their built/spare-parts/notes state. Back up the database before changing its schema and apply related changes transactionally where SQLite permits.

This is schema extension of the existing database, not a separate database migration project: do not introduce a formal migration-chain framework or copy data into a new database. Schema setup should safely detect whether BrickStack2's required tables and columns are present, add only what is missing, and be safe to run again. Do not repurpose the existing `BSDBVersions` table, which tracks imported catalogue data, as a BrickStack2 user-schema version. Keep all existing catalogue tables in the same database file.

In-place schema continuity does not automatically make simultaneous v1 and BrickStack2 writers safe: the existing desktop app has no account context and cannot assign ownership to new rows. Do not claim concurrent backward compatibility without a tested ownership strategy; document whether running both versions against the same database is unsupported.

Passwords must be securely hashed; sessions/tokens must be revocable; share links must be unguessable, scoped, and read-only. Every endpoint must enforce role and collection ownership on the server, independently of which controls the UI displays.

**Account policy decisions:** Self-registration is disabled by default and can only be enabled by an administrator. An enabled registration grants only the configured non-admin role. Authenticated non-admin users can view and modify only their own collection, except for an explicitly assigned read-only viewer scope. Admins can inspect other accounts and their stored collection data through an authorized, audited, read-only inspection path; this does not itself authorize editing those collections.

## Decisions to confirm before implementation

These are intentionally open questions to review together; they do not block architecture research or the initial project bootstrap.

- **First-release network exposure:** Should the default be localhost-only, with LAN access as an explicit configuration option, or should LAN access be a supported first-run mode? Public exposure should require a reverse proxy/TLS setup either way.
- **Desktop debug host:** Should the VCL development host only start/stop the server and open the system browser, or should an embedded browser be an initial requirement?
- **Rebrickable credentials:** Should each user configure their own API key and account token, or should the server administrator provide a shared API key while users provide their own account tokens? Credentials must remain server-side.
- **First administrator:** What first-run flow should create the initial administrator (for example, a one-time setup page while the server is local-only, or a generated one-time setup token)?
- **Viewer access:** Should a viewer be linked to one member's collection by an administrator, and should share links be included in the first release or deferred?

## Delivery phases

### 1. Bootstrap the two-service web slice

**Goal:** Finish Phase 1 with a basic BrickStack2 page visible in a browser. A Delphi WebBroker UI server serves the page and makes a server-side request to a separate Delphi WebBroker backend service. The backend returns dummy JSON; the UI displays it. This proves the browser-to-UI-server-to-backend-server path before connecting any real data.

**Status: Complete.** The UI, backend, and DUnit projects are built. The DUnit test and HTTP smoke checks pass; each service runs in its own console and can be stopped independently, the browser displays backend dummy data through the UI server, and unknown paths/unsupported methods return 404/405 responses. The launcher reuses already healthy services.

- Keep the Delphi group project (`.groupproj`) at the `BrickStack2\` root. Put the backend, UI, and test Delphi project files under `Src\Backend\`, `Src\UI\`, and `Src\Tests\` respectively; keep shared source under `Src\` and project-specific source/assets with their owning area.
- Bind both development services to loopback by default, on documented separate ports. Provide a convenient way to start them and open the UI in a browser.
- Have the UI server fetch the dummy data from the backend. The browser calls only the UI server; it must not call the backend directly. Show a clear error in the page if the backend is unavailable rather than silently substituting dummy data in the UI server.
- Add health endpoints for each service, DUnit coverage for the dummy JSON, and HTTP smoke checks for the service endpoints and server-to-server request.
- Keep the completed demo's loopback binding, same-origin browser access, method/path rejection, and safe backend-error behavior in the repeatable smoke/security checks.
- Configure build outputs so neither service overwrites the existing application's outputs or the other service's outputs.
- Confirm both projects build with Delphi 13 Community Edition and the installed Windows SDK, and the DUnit suite runs.
- **Phase 1 does not connect to SQLite, alter the existing database, or implement user-management schema.** Those start with the real-data work in Phase 2.
- Establish representative baseline data and draft measurable performance targets for the key journeys before implementing feature endpoints.

### 2. Build a read-only vertical slice

- Implement idempotent schema setup that adds BrickStack2's account and ownership tables and columns to the existing SQLite database, preserving its catalogue and collection data; do not create a separate database or formal migration chain. Test setup against a copy of an existing database.
- Add a database/repository layer with parameterized queries and managed connection lifetimes appropriate for concurrent web requests; use the existing database and read its preserved collection through the new ownership model.
- Expose read endpoints for overview totals, set lists, and sets in a list.
- Render the corresponding overview, list pane, and set detail using the reference layout.
- Add focused DUnit tests for query results, endpoint response shape, invalid input, and database errors.
- Add OWASP/ASVS-driven tests for unauthenticated and cross-collection reads, input handling, and data/error disclosure before exposing the read endpoints beyond localhost.
- Verify generic public error codes against protected internal diagnostics: no SQL text, filesystem paths, stack traces, configuration, or secrets may leak to clients.
- Measure the read-only journeys against representative data; tune query/index/pagination design and record the baseline and targets.

### 3. Add collection operations

- Implement and validate edits through explicit API operations: set/list creation and updates, quantities, notes, and removal.
- Add server-side input validation, authorization checks, transactions where needed, and tests for failure and concurrency cases.
- Add request-level security tests for authentication, role enforcement, ownership checks, CSRF protections when applicable, and attempts to bypass UI restrictions.
- Test that users cannot enumerate, view, or modify another user's records by manipulating IDs or request payloads; test admin inspection authorization, read-only behavior, and audit logging.
- Test schema setup against a copy of an existing BrickStack database, verifying existing catalogue and collection data is preserved, ownership is assigned correctly, rerunning setup is safe, and failures do not leave partial schema changes.

### 4. Add catalog and integrations

- Add search and set/part/minifig detail views using the available catalogue database.
- Implement import/export and Rebrickable sync behind Delphi services.
- Keep API keys on the server. Add bounded download queues, backoff, and local image caching before serving images to browsers.

### 5. Complete accounts, roles, and sharing

- Complete account workflows and role enforcement across every relevant endpoint, not only UI visibility. The account and ownership schema are already present from the initial release.
- Test that public account creation is disabled by default, only an administrator can enable it, and new accounts cannot choose an elevated role.
- Provide admins with audited, privileged inspection of user accounts and stored collection data without implicitly granting cross-user edit permission.
- Add the account administration and viewer workflows from the design plan.
- Add public share routes with explicit read-only scope and tests that verify they cannot mutate data or reveal unrelated collections.
- Verify account recovery, session/token lifecycle, credential handling, privilege boundaries, and share-link abuse cases against applicable OWASP ASVS requirements.

### 6. Packaging and deployment

- Document Windows self-hosting, configuration, database backups, upgrades, and network exposure.
- Keep default binding local-only; require deliberate configuration for LAN/public access and explain reverse-proxy/TLS expectations.
- Re-run the performance checks with representative data and documented hardware/configuration; address regressions against the agreed targets before release.
- Complete the applicable OWASP ASVS release checklist, resolve high-risk security findings, and perform an independent security assessment before enabling public production access.
- Recheck current Community Edition eligibility, platform support, and any deployment requirements before release.

## Initial API sketch

Keep names and response shapes consistent once implementation starts; this is an initial boundary, not a fixed contract:

- `GET /api/health`
- `GET /api/overview`
- `GET /api/set-lists`
- `GET /api/set-lists/{id}/sets`
- `GET /api/sets/{id}`

Add write, search, import, sync, account, and share endpoints only alongside their authorization and tests.

## UI direction

- Use the chosen 1b master-detail layout: navigation rail, list pane, and detail pane.
- Start with responsive overview, set lists, and set detail; progressively implement parts, minifigs, search, and settings.
- Keep theme and visual tokens in CSS variables. Treat the demo's placeholder data and UI-only interactions as non-production.
- Ensure core navigation and collection operations remain usable on narrow/mobile screens.

## Definition of a first usable milestone

BrickStack2 is independently buildable with Delphi 13 Community Edition and the configured Windows SDK, and its DUnit suite runs. The Phase 1 milestone is the UI server serving a browser page that displays dummy data fetched server-to-server from the separate backend. By the end of Phase 2, BrickStack2 also uses the existing SQLite database, safely extends its schema with user-management tables and columns without losing existing data, and displays real overview/list/set data through read-only API endpoints with multi-user collection ownership enforced. The existing BrickStack project still opens and builds independently.

## Source references

- [Design plan](../Misc/brickstack-design-plan.md)
- [Bundled UI demo](../Misc/BrickStack-demo.html)
- [Existing database creation and version scripts](../Src/Scripts/UBSSQL.pas)
- [Existing main VCL form](../Src/Frames/UFrmMain.pas)
