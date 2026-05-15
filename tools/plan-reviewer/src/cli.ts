import * as fs from "fs";
import * as path from "path";
import { startServer } from "./server";

async function main() {
  const filePath = process.argv[2];
  if (!filePath) {
    console.error("Usage: plan-reviewer <plan-file.md>");
    process.exit(1);
  }

  const resolvedPath = path.resolve(filePath);
  if (!fs.existsSync(resolvedPath)) {
    console.error(`File not found: ${resolvedPath}`);
    process.exit(1);
  }

  const content = fs.readFileSync(resolvedPath, "utf8");
  const fileName = path.basename(resolvedPath);

  const result = await startServer({ content, filePath: resolvedPath, fileName });
  process.stdout.write(JSON.stringify(result, null, 2) + "\n");
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
