import * as fs from "fs";
import * as path from "path";
import { Hono } from "hono";
import { serve } from "@hono/node-server";
import open from "open";

const PORT = 3848;
const PUBLIC_DIR = path.join(__dirname, "..", "public");

interface ServerOptions {
  content: string;
  filePath: string;
  fileName: string;
}

export function startServer(options: ServerOptions): Promise<unknown> {
  return new Promise((resolve) => {
    const app = new Hono();

    app.get("/", (c) => {
      const html = fs.readFileSync(path.join(PUBLIC_DIR, "index.html"), "utf8");
      const injected = html.replace(
        "</body>",
        `<script>
window.__PLAN_CONTENT__ = ${JSON.stringify(options.content)};
window.__PLAN_PATH__ = ${JSON.stringify(options.filePath)};
window.__PLAN_NAME__ = ${JSON.stringify(options.fileName)};
</script></body>`
      );
      return c.html(injected);
    });

    app.get("/editor.bundle.js", (c) => {
      const buf = fs.readFileSync(path.join(PUBLIC_DIR, "editor.bundle.js"));
      return new Response(buf, {
        headers: { "Content-Type": "application/javascript" },
      });
    });

    app.get("/styles.css", (c) => {
      const css = fs.readFileSync(path.join(PUBLIC_DIR, "styles.css"), "utf8");
      return new Response(css, { headers: { "Content-Type": "text/css" } });
    });

    app.post("/api/submit", async (c) => {
      const body = await c.req.json();
      setTimeout(() => resolve(body), 150);
      return c.json({ ok: true });
    });

    serve({ fetch: app.fetch, port: PORT }, (info) => {
      const url = `http://localhost:${info.port}`;
      console.error(`Plan reviewer → ${url}`);
      open(url);
    });
  });
}
