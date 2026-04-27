import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "path";
import fs from "fs";

// Custom plugin: serve /data/silver/*.json from the project root during dev.
// During build, the JSON files are copied into dist/ by the build hook below.
function serveDataPlugin() {
  const projectRoot = resolve(__dirname, "..");

  return {
    name: "serve-data",
    configureServer(server) {
      server.middlewares.use((req, res, next) => {
        if (!req.url?.startsWith("/data/silver/")) return next();
        const rel = req.url.slice(1); // strip leading /
        const filePath = resolve(projectRoot, rel);
        if (fs.existsSync(filePath)) {
          res.setHeader("Content-Type", "application/json");
          res.end(fs.readFileSync(filePath));
        } else {
          res.statusCode = 404;
          res.end("Not found");
        }
      });
    },
    closeBundle() {
      // Copy data/silver/ into dist/data/silver/ after build
      const src = resolve(projectRoot, "data", "silver");
      const dest = resolve(__dirname, "dist", "data", "silver");
      if (fs.existsSync(src)) {
        fs.mkdirSync(dest, { recursive: true });
        for (const file of fs.readdirSync(src)) {
          fs.copyFileSync(resolve(src, file), resolve(dest, file));
        }
      }
    },
  };
}

export default defineConfig({
  plugins: [react(), serveDataPlugin()],
  root: ".",
  publicDir: false,
  build: {
    outDir: "dist",
  },
  server: {
    port: 5173,
  },
});
