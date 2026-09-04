import { fileURLToPath } from "node:url";

import starlight from "@astrojs/starlight";
import { defineConfig } from "astro/config";
import mermaid from "astro-mermaid";
import starlightThemeRapide from "starlight-theme-rapide";

import { dropLeadingHeading } from "./src/plugins/drop-leading-heading.mjs";
import { rewriteMarkdownLinks } from "./src/plugins/rewrite-markdown-links.mjs";

const BASE = "/profile.d";
const DOCS_ROOT = fileURLToPath(new URL("../docs", import.meta.url));

// Where a link the site does not publish is sent; pinned to the published branch.
const REPOSITORY = "https://github.com/jakubro/profile.d";
const REF = "main";

// Ordered by what a reader needs first - a task before a contract, never alphabetically.
const SIDEBAR = [
  {
    label: "Start",
    items: [
      { label: "What profile.d is", slug: "index" },
      { label: "Your first shell", slug: "start" },
    ],
  },
  {
    label: "Guides",
    items: [
      { label: "Managing plugins", slug: "guide/plugins" },
      { label: "The hook lifecycle", slug: "guide/lifecycle" },
      { label: "What happens to your dotfiles", slug: "guide/dotfiles" },
      { label: "Writing a plugin", slug: "guide/authoring" },
      { label: "When something goes wrong", slug: "guide/troubleshooting" },
    ],
  },
  {
    label: "Plugins",
    items: [
      { label: "autojump", slug: "plugins/autojump" },
      { label: "direnv", slug: "plugins/direnv" },
      { label: "hstr", slug: "plugins/hstr" },
      { label: "liquidprompt", slug: "plugins/liquidprompt" },
      { label: "nvm", slug: "plugins/nvm" },
      { label: "pyenv", slug: "plugins/pyenv" },
    ],
  },
  {
    label: "Reference",
    items: [{ label: "Hooks", slug: "reference/hooks" }],
  },
  {
    label: "Internal",
    collapsed: true,
    items: [{ label: "Architecture", slug: "architecture" }],
  },
];

export default defineConfig({
  site: "https://jakubro.github.io",
  base: BASE,
  trailingSlash: "always",
  markdown: {
    smartypants: false,
    remarkPlugins: [
      dropLeadingHeading,
      [rewriteMarkdownLinks, { docsRoot: DOCS_ROOT, base: BASE, repository: REPOSITORY, ref: REF }],
    ],
  },
  integrations: [
    // Claims fenced mermaid blocks before Starlight's renderer sees them, so it must stay first.
    mermaid({ autoTheme: true }),
    starlight({
      title: "profile.d",
      plugins: [starlightThemeRapide()],
      components: { ThemeProvider: "./src/components/ThemeProvider.astro" },
      // Inlined rather than emitted: trailingSlash "always" appends a slash to the hashed
      // /_astro/ec.<hash>.css route, so the dev server never matches it and code blocks lose styling.
      expressiveCode: { emitExternalStylesheet: false },
      sidebar: SIDEBAR,
      customCss: ["./src/styles/custom.css"],
      social: [{ icon: "github", label: "GitHub", href: REPOSITORY }],
    }),
  ],
});
