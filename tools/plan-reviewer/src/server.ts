import * as fs from "fs";
import * as path from "path";
import * as net from "net";
import { Hono } from "hono";
import { serve } from "@hono/node-server";
import open from "open";

const PREFERRED_PORT = 3848;
const PUBLIC_DIR = path.join(__dirname, "..", "public");
const WATCHDOG_MS = 7_000;

function findFreePort(start: number): Promise<number> {
  return new Promise((resolve, reject) => {
    const server = net.createServer();
    server.listen(start, () => {
      const port = (server.address() as net.AddressInfo).port;
      server.close(() => resolve(port));
    });
    server.on("error", () =>
      start < 3900 ? resolve(findFreePort(start + 1)) : reject(new Error("No free port found"))
    );
  });
}

interface ServerOptions {
  content: string;
  filePath: string;
  fileName: string;
}

export async function startServer(options: ServerOptions): Promise<{ result: unknown; close: () => void }> {
  const port = await findFreePort(PREFERRED_PORT);
  return new Promise((resolve) => {
    const app = new Hono();
    let resolved = false;

    function doResolve(result: unknown) {
      if (resolved) return;
      resolved = true;
      clearTimeout(watchdogTimer);
      resolve({ result, close: () => { try { httpServer.close(); } catch {} } });
    }

    let watchdogTimer: NodeJS.Timeout = setTimeout(() => doResolve({ action: "timeout" }), WATCHDOG_MS);

    function resetWatchdog() {
      clearTimeout(watchdogTimer);
      watchdogTimer = setTimeout(() => doResolve({ action: "timeout" }), WATCHDOG_MS);
    }

    app.get("/", (c) => {
      const home = process.env.HOME ?? "";
      const displayPath = home && options.filePath.startsWith(home)
        ? "~" + options.filePath.slice(home.length)
        : options.filePath;

      const html = fs.readFileSync(path.join(PUBLIC_DIR, "index.html"), "utf8");
      const injected = html.replace(
        "</body>",
        `<script>
window.__PLAN_CONTENT__ = ${JSON.stringify(options.content)};
window.__PLAN_PATH__ = ${JSON.stringify(options.filePath)};
window.__PLAN_NAME__ = ${JSON.stringify(options.fileName)};
window.__PLAN_DISPLAY_PATH__ = ${JSON.stringify(displayPath)};
</script></body>`
      );
      return c.html(injected);
    });

    app.get("/editor.bundle.js", (c) => {
      const buf = fs.readFileSync(path.join(PUBLIC_DIR, "editor.bundle.js"));
      return new Response(buf, { headers: { "Content-Type": "application/javascript" } });
    });

    app.get("/styles.css", (c) => {
      const css = fs.readFileSync(path.join(PUBLIC_DIR, "styles.css"), "utf8");
      return new Response(css, { headers: { "Content-Type": "text/css" } });
    });

    app.get("/api/heartbeat", (c) => {
      resetWatchdog();
      return c.json({ ok: true });
    });

    app.post("/api/submit", async (c) => {
      const body = await c.req.json();
      setTimeout(() => doResolve(body), 150);
      return c.json({ ok: true });
    });

    const httpServer = serve({ fetch: app.fetch, port }, (info) => {
      const url = `http://localhost:${info.port}`;
      const msg = `Plan reviewer → ${url}`;
      const cols = process.stdout.columns || 80;
      const rows = process.stdout.rows || 24;
      const hPad = " ".repeat(Math.max(0, Math.floor((cols - msg.length) / 2)));
      const vPad = "\n".repeat(Math.max(0, Math.floor(rows / 2) - 1));
      process.stdout.write(vPad + hPad + msg + "\n");
      open(url);
    });
  });
}
