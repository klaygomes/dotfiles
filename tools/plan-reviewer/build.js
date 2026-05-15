const { build } = require("esbuild");

async function main() {
  await Promise.all([
    build({
      entryPoints: ["src/cli.ts"],
      bundle: true,
      outfile: "dist/cli.js",
      format: "cjs",
      platform: "node",
      banner: { js: "#!/usr/bin/env node" },
    }),
    build({
      entryPoints: ["public/editor.ts"],
      bundle: true,
      outfile: "public/editor.bundle.js",
      format: "iife",
      platform: "browser",
    }),
  ]);
  console.log("Build complete.");
}

main().catch(() => process.exit(1));
