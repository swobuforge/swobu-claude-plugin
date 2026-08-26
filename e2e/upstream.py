#!/usr/bin/env python3
import http.server
import json
import sys


class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        self.rfile.read(int(self.headers.get("Content-Length", "0")))
        body = json.dumps({
            "id": "e2e",
            "type": "message",
            "role": "assistant",
            "content": [{"type": "text", "text": "SWOBU_E2E_OK"}],
            "stop_reason": "end_turn",
        }).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    http.server.HTTPServer(("127.0.0.1", int(sys.argv[1])), Handler).serve_forever()
