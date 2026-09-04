#!/usr/bin/env node
// Astro caches parsed content and does not invalidate it when a remark plugin changes, so an
// edited link rewriter can report a clean build over stale pages. CI never sees this - it always
// starts fresh - which is exactly why the local build has to.

import { rmSync } from "node:fs";
import { fileURLToPath } from "node:url";

for (const name of ["../dist", "../.astro", "../node_modules/.astro"]) {
  rmSync(fileURLToPath(new URL(name, import.meta.url)), { recursive: true, force: true });
}
