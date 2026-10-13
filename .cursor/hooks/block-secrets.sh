#!/bin/bash
input=$(cat)
if echo "$input" | grep -qE '\.env|/secrets/'; then
    echo '{"permission": "deny", "user_message": "Blocked: secrets files are off limits to agents."}'
else
    echo '{"permission": "allow"}'
fi
