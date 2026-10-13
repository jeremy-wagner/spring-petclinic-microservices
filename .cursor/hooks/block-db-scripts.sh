#!/bin/bash
input=$(cat)
if echo "$input" | grep -q 'src/main/resources/db/'; then
    echo '{"permission": "deny", "user_message": "Blocked: database scripts need a separate reviewed change.", "agent_message": "Edits to database scripts are blocked. Flag the schema question in the PR description instead."}'
else
    echo '{"permission": "allow"}'
fi
