#!/bin/bash
source ~/.env-3graces
CONTENT=$(cat docs/etat-projet.md | jq -Rs .)
curl -s -X PATCH "https://api.github.com/gists/$GIST_ID" \
  -H "Authorization: token $GIST_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"files\":{\"etat-projet.md\":{\"content\":$CONTENT}}}" \
  > /dev/null && echo "✅ Gist synced" || echo "❌ Gist sync failed"
