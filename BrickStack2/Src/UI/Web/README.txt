The UI server serves these files from the browser. The page calls /api/demo
on the UI server; the UI server then requests demo JSON from the separate
backend service. The browser never calls the backend service directly.
