"""Registers the offline service worker and sets the app name in the web build files.

Run after `flutter create . --platforms=web`.
"""
import json
import pathlib
import re
import sys

index = pathlib.Path("web/index.html")
html = index.read_text(encoding="utf-8")

if "sw.js" not in html:
    snippet = (
        "<script>\n"
        "if ('serviceWorker' in navigator) {\n"
        "  window.addEventListener('load', function () {\n"
        "    navigator.serviceWorker.register('sw.js');\n"
        "  });\n"
        "}\n"
        "</script>\n"
    )
    if "</body>" not in html:
        sys.exit("could not find </body> in web/index.html")
    html = html.replace("</body>", snippet + "</body>", 1)

html = re.sub(r"<title>.*?</title>", "<title>SafePath</title>", html, count=1)
index.write_text(html, encoding="utf-8")

manifest = pathlib.Path("web/manifest.json")
if manifest.exists():
    data = json.loads(manifest.read_text(encoding="utf-8"))
    data["name"] = "SafePath"
    data["short_name"] = "SafePath"
    data["description"] = "Offline emergency companion"
    manifest.write_text(json.dumps(data, indent=2), encoding="utf-8")

print("web patched")
