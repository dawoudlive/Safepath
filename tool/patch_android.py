import pathlib
import re
import sys

path = pathlib.Path("android/app/src/main/AndroidManifest.xml")
text = path.read_text(encoding="utf-8")

if "ACCESS_FINE_LOCATION" in text:
    print("already patched")
    sys.exit(0)

perms = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
"""
queries = """    <queries>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="tel"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="sms"/></intent>
        <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
    </queries>
"""

marker = "<application"
if marker not in text:
    sys.exit("could not find <application in manifest")
text = text.replace(marker, perms + queries + "    " + marker, 1)
text = re.sub(r'android:label="[^"]*"', 'android:label="SafePath"', text, count=1)

path.write_text(text, encoding="utf-8")
print("patched")
