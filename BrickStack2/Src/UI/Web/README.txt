The UI server serves these files to the browser. The page requests catalog
totals, set/part search results, filter lookups, and selected-item details from
same-origin /api/catalog routes. The UI server proxies only approved routes to
the separate backend; the browser never calls the backend directly.

The profile dialog supports password replacement for provisioned accounts and,
for the signed-in Global Admin, account listing and ordinary-user creation.
Generated temporary passwords are returned once and must be replaced before
the new account can sign in.
