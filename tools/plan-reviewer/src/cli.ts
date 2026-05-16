import * as fs from "fs";
import * as path from "path";
import { startServer } from "./server";

interface Annotation {
  text: string;
  comment: string;
  range: { from: { line: number; col: number }; to: { line: number; col: number } } | null;
}

function buildReviewHeader(body: Record<string, unknown>): string {
  const action = body.action as string;
  const summary = body.summary as string | undefined;
  const annotations = (body.annotations as Annotation[] | undefined) ?? [];

  const lines: string[] = ["<!--review"];
  lines.push(`action: ${action}`);

  if (summary) {
    lines.push(`summary: |`);
    for (const l of summary.split("\n")) lines.push(`  ${l}`);
  }

  if (annotations.length > 0) {
    lines.push(`annotations:`);
    for (const ann of annotations) {
      const quote = ann.text.replace(/\n/g, " ").trim();
      lines.push(`  - quote: "${quote}"`);
      lines.push(`    comment: "${ann.comment}"`);
      if (ann.range) {
        const { from, to } = ann.range;
        lines.push(`    range: "line ${from.line} col ${from.col} → line ${to.line} col ${to.col}"`);
      }
    }
  }

  lines.push("-->");
  return lines.join("\n") + "\n\n";
}

function stripReviewHeader(content: string): string {
  if (!content.startsWith("<!--review")) return content;
  const end = content.indexOf("-->");
  if (end === -1) return content;
  return content.slice(end + 3).replace(/^\n+/, "");
}

async function main() {
  const filePath = process.argv[2];
  if (!filePath) process.exit(1);

  const resolvedPath = path.resolve(filePath);
  if (!fs.existsSync(resolvedPath)) process.exit(1);

  const raw = fs.readFileSync(resolvedPath, "utf8");
  const content = stripReviewHeader(raw);
  const fileName = path.basename(resolvedPath);

  const { result, close } = await startServer({ content, filePath: resolvedPath, fileName });
  const body = result as Record<string, unknown>;

  if (body.action !== "timeout") {
    const modifiedPlan = typeof body.modifiedPlan === "string" ? body.modifiedPlan : content;
    const header = buildReviewHeader(body);
    fs.writeFileSync(resolvedPath, header + modifiedPlan, "utf8");
  }

  close();
  process.stdout.write(JSON.stringify(body, null, 2) + "\n");
  process.exit(0);
}

main().catch(() => process.exit(1));
