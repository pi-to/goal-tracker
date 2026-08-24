#!/usr/bin/env python3
"""Static file server with PUT /cloud-config.json so one admin paste is shared."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CFG = ROOT / "cloud-config.json"
PORT = 8080


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_PUT(self):
        if self.path.split("?", 1)[0] != "/cloud-config.json":
            self.send_error(404)
            return
        n = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(n)
        try:
            obj = json.loads(raw.decode("utf-8"))
        except Exception:
            self.send_error(400, "invalid json")
            return
        if not isinstance(obj, dict) or not obj.get("apiKey") or not obj.get("projectId"):
            self.send_error(400, "apiKey and projectId required")
            return
        keep = {
            k: obj[k]
            for k in (
                "apiKey",
                "authDomain",
                "projectId",
                "storageBucket",
                "messagingSenderId",
                "appId",
                "measurementId",
            )
            if k in obj and obj[k]
        }
        CFG.write_text(json.dumps(keep, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        body = b'{"ok":true}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    httpd = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    print(f"serving {ROOT} on :{PORT}", flush=True)
    httpd.serve_forever()
