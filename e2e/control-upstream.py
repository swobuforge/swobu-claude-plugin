#!/usr/bin/env python3
import json
import re
import shlex
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(sys.argv[1])
REQUEST_PATH = sys.argv[2] if len(sys.argv) > 2 else f"/tmp/e2e/control-{PORT}-request.json"
class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.0"
    request_number = 0

    def do_GET(self):
        data = b'{"data":[{"id":"claude-haiku-4-5","display_name":"Claude Haiku 4.5"}]}'
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        request_body = self.rfile.read(length)
        with open(REQUEST_PATH, "wb") as request_file:
            request_file.write(request_body)
        payload = json.loads(request_body)
        Handler.request_number += 1

        tool_results = [
            item
            for message in payload.get("messages", [])
            for item in (message.get("content") if isinstance(message.get("content"), list) else [])
            if isinstance(item, dict) and item.get("type") == "tool_result"
        ]
        prompt = "".join(
            item.get("text", "")
            for message in payload.get("messages", [])
            for item in (message.get("content") if isinstance(message.get("content"), list) else [])
            if isinstance(item, dict) and item.get("type") == "text"
        )
        is_setup = "<command-name>/swobu:setup</command-name>" in prompt
        is_status = "<command-name>/swobu:status</command-name>" in prompt

        if not tool_results:
            content, stop_reason = self.initial_response(prompt, is_setup, is_status)
        else:
            content, stop_reason = self.tool_result_response(tool_results[-1], is_setup, is_status)

        body = {
            "id": f"msg_control_e2e_{Handler.request_number}",
            "type": "message",
            "role": "assistant",
            "model": "claude-haiku-4-5",
            "content": content,
            "stop_reason": stop_reason,
            "stop_sequence": None,
            "usage": {"input_tokens": 1, "output_tokens": 1},
        }
        data = json.dumps(body).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def initial_response(self, prompt, is_setup, is_status):
        if is_setup:
            command = "command -v swobu"
        elif is_status:
            command = "swobu status"
        else:
            match = re.search(r"Arguments passed:\s*`([^`]*)`", prompt)
            workspace = match.group(1) if match else ""
            command = "swobu connect claude"
            if workspace:
                command += f" --workspace {shlex.quote(workspace)}"

        return ([{
            "type": "tool_use",
            "id": f"toolu_e2e_{Handler.request_number}",
            "name": "Bash",
            "input": {"command": command},
        }], "tool_use")

    def tool_result_response(self, tool_result, is_setup, is_status):
        result = tool_result.get("content", "")
        if not isinstance(result, str):
            result = "\n".join(str(part) for part in result)

        if "Existing client configuration would be replaced." in result or "Run again with --replace" in result:
            text = "Replacement is required. Replace the existing endpoint?"
        elif tool_result.get("is_error"):
            lines = [
                line.strip()
                for line in result.splitlines()
                if line.strip()
                and not line.startswith("Exit code ")
                and not line.startswith("<system-reminder>")
                and not line.startswith("USD budget:")
            ]
            command_not_found = is_setup and not lines
            text = (
                "Swobu is not installed.\nOfficial install command:\n\n"
                "curl -fsSL https://swobu.com/install.sh | sh"
                if command_not_found
                else (lines[0] if lines else "Swobu command failed.")
            )
        elif is_setup:
            text = "Swobu is installed."
        elif is_status:
            text = "Swobu status was retrieved."
        else:
            text = "Claude Code is configured for the selected workspace."

        return ([{"type": "text", "text": text}], "end_turn")

    def log_message(self, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
