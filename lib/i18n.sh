#!/bin/bash

SCRIPT_LANG="${SCRIPT_LANG:-en}"
_LOCALE_FILE="$SCRIPT_DIR/locales/${SCRIPT_LANG}.json"

[ ! -f "$_LOCALE_FILE" ] && _LOCALE_FILE="$SCRIPT_DIR/locales/en.json"

_LOCALE_JSON=$(cat "$_LOCALE_FILE")

t() {
    printf '%s' "$_LOCALE_JSON" | jq -r --arg key "$1" '.[$key] // $key'
}
