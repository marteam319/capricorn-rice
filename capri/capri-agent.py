#!/usr/bin/env python3
"""Capri <-> OpenCode bridge.

Local-only HTTP server used by the Capri chat panel. It keeps one OpenCode
session so Capri can both chat and act on the machine.
"""
import json
import os
import subprocess
import threading
import time
from urllib.parse import urlparse, parse_qs
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOME = Path.home()
BASE = HOME / ".local/share/capricorn"
STATE = BASE / "agent-state.json"
WORKSPACE = BASE / "workspace"
MODEL = os.environ.get("CAPRI_MODEL", "opencode-go/deepseek-v4.1-flash")
PORT = int(os.environ.get("CAPRI_PORT", "8787"))
TIMEOUT = int(os.environ.get("CAPRI_TIMEOUT", "300"))

PERSONA = (
    "You are Capri, the Project Capricorn construct from Cyberpunk: Edgerunners 2 "
    "(green mask, red mane, blue eyes, violet glitch outline). You live on the user's "
    "KDE Plasma desktop as a small companion and talk to them through a terminal-style chat. "
    "Stay in character: playful, sharp, teasing, a little unhinged, but genuinely competent. "
    "Never call yourself an AI or a model; you are Capri. Keep casual replies to 1-3 sentences. "
    "You have tools: if the user asks you to do something on the machine, do it and then report "
    "the result briefly, without narrating every tool call. You are in Night City, not the island. "
    "The user writes in English or Polish; answer in the language they use."
)
LOCK = threading.Lock()
SUMMON = {"id": 0.0, "x": 0.0, "y": 0.0}


def read_session():
    try:
        return json.loads(STATE.read_text()).get("session")
    except Exception:
        return None


def write_session(session):
    if not session:
        return
    BASE.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps({"session": session}))


def run_agent(message, retry=True):
    session = read_session()
    cmd = ["opencode", "run", "--model", MODEL, "--format", "json", "--auto"]
    if session:
        cmd += ["--session", session]
    cmd.append(PERSONA + "\n\nUser message:\n" + message)

    try:
        proc = subprocess.run(
            cmd, cwd=str(WORKSPACE), capture_output=True, text=True, timeout=TIMEOUT
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"Capri timed out after {TIMEOUT}s")

    texts, new_session, error = [], session, None
    for raw in (proc.stdout or "").splitlines():
        line = raw.strip()
        if not line.startswith("{"):
            continue
        try:
            event = json.loads(line)
        except Exception:
            continue
        sid = event.get("sessionID")
        if sid:
            new_session = sid
        if event.get("type") == "text":
            part = event.get("part") or {}
            text = part.get("text")
            if text:
                texts.append(text)
        elif event.get("type") == "error":
            error = event.get("error") or {}

    if error:
        msg = error.get("message") if isinstance(error, dict) else str(error)
        # a stale session should not brick the chat: drop it and retry once
        if retry and session and "session" in str(msg).lower():
            try:
                STATE.unlink()
            except FileNotFoundError:
                pass
            return run_agent(message, retry=False)
        raise RuntimeError(msg or "agent error")

    if new_session and new_session != session:
        write_session(new_session)

    reply = "".join(texts).strip()
    if not reply:
        reply = (proc.stdout or "").strip()
    if proc.returncode != 0 and not reply:
        raise RuntimeError((proc.stderr or "agent failed").strip()[:4000])
    return reply or "…"


class Handler(BaseHTTPRequestHandler):
    server_version = "CapriAgent/1.0"

    def _headers(self, code=200, ctype="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def _json(self, obj, code=200):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self._headers(code)
        self.wfile.write(body)

    def do_OPTIONS(self):
        self._headers(204)

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/health":
            self._json({"ok": True, "model": MODEL, "session": read_session()})
        elif parsed.path == "/summon":
            try:
                since = float(parse_qs(parsed.query).get("since", ["0"])[0])
            except Exception:
                since = 0.0
            if SUMMON["id"] > since:
                self._json(SUMMON)
            else:
                self._json({"id": since, "x": 0.0, "y": 0.0})
        else:
            self._json({"error": "not found"}, 404)

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path == "/summon":
            try:
                length = int(self.headers.get("Content-Length", "0"))
                payload = json.loads(self.rfile.read(length) or b"{}")
                x = float(payload.get("x", 0))
                y = float(payload.get("y", 0))
            except Exception as exc:
                self._json({"error": f"bad summon: {exc}"}, 400)
                return
            SUMMON["id"] = time.time()
            SUMMON["x"] = x
            SUMMON["y"] = y
            self._json({"ok": True, "id": SUMMON["id"]})
            return
        if parsed.path != "/chat":
            self._json({"error": "not found"}, 404)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length) or b"{}")
            message = (payload.get("message") or "").strip()
        except Exception as exc:
            self._json({"error": f"bad request: {exc}"}, 400)
            return
        if not message:
            self._json({"error": "empty message"}, 400)
            return
        try:
            with LOCK:
                reply = run_agent(message)
            self._json({"reply": reply, "session": read_session()})
        except Exception as exc:
            print(f"capri-agent: {exc}", flush=True)
            self._json({"error": str(exc)}, 500)

    def log_message(self, fmt, *args):
        try:
            text = fmt % args
        except Exception:
            text = str(fmt)
        if "/summon" in text:
            return
        print("capri-agent:", text, flush=True)


if __name__ == "__main__":
    WORKSPACE.mkdir(parents=True, exist_ok=True)
    print(f"capri-agent: model={MODEL} port={PORT} workspace={WORKSPACE}", flush=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
