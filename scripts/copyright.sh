#!/bin/bash

# This script automates the process of adding a standard Microsoft copyright header
# to source files in the repository.
#
# It applies the correct comment style for Python files (.py),
# and targets all Python files in the project.
#
# The script is idempotent, meaning it won't add a header if one already exists.

# This script adds a copyright notice to relevant source files in the repository
# that do not already have it.

# Copyright text for languages using # comments (Python)
read -r -d '' COPYRIGHT_TEXT_HASH <<'EOF'
# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.
EOF

CHECK_STRING_HASH=$(echo "$COPYRIGHT_TEXT_HASH" | head -n 1)

# Use git ls-files to find all tracked and untracked relevant files.
# This is better than `find` because it respects .gitignore.
# We look for .py files everywhere.
{ 
    git ls-files -- '*.py'; 
    git ls-files --others --exclude-standard -- '*.py';
} | sort -u | while read -r file; do
    # Ensure the file exists and is a regular file
    if [ ! -f "$file" ]; then
        continue
    fi

    COPYRIGHT_TEXT=""
    CHECK_STRING=""

    case "$file" in
        *.py)
            COPYRIGHT_TEXT="$COPYRIGHT_TEXT_HASH"
            CHECK_STRING="$CHECK_STRING_HASH"
            ;;
        *)
            continue
            ;;
    esac

    # Check if the file already contains the copyright string. If so, skip.
    if grep -qF "$CHECK_STRING" "$file"; then
        continue
    fi

    echo "Adding copyright to $file"
    
    # Handle shebangs for script files
    SHEBANG=""
    FILE_CONTENT_PATH="$file"
    if [[ "$file" == *.py ]] && head -n 1 "$file" | grep -q '^#!'; then
        SHEBANG=$(head -n 1 "$file")
        # Use a temporary file to strip the shebang for processing
        TMP_NO_SHEBANG=$(mktemp)
        tail -n +2 "$file" > "$TMP_NO_SHEBANG"
        FILE_CONTENT_PATH="$TMP_NO_SHEBANG"
    fi

    # Prepend the copyright text to the file
    TMPFILE=$(mktemp)

    # Write shebang if it exists
    if [ -n "$SHEBANG" ]; then
        echo "$SHEBANG" > "$TMPFILE"
        echo "" >> "$TMPFILE"
    fi
    
    echo "$COPYRIGHT_TEXT" >> "$TMPFILE"
    echo "" >> "$TMPFILE"
    cat "$FILE_CONTENT_PATH" >> "$TMPFILE"
    mv "$TMPFILE" "$file"

    # Clean up temp file if created
    if [ -n "$SHEBANG" ]; then
        rm "$TMP_NO_SHEBANG"
    fi
done

echo "Copyright check and update complete."
