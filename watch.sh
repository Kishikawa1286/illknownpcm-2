#!/bin/bash

SCRIPT_DIR=$(dirname "$0")
WATCH_DIR="$SCRIPT_DIR/src/"

# File to save the previous state
PREV_STATE_FILE="$SCRIPT_DIR/.prev_state"

run_task() {
    # Find all .jmd files and process them
    find "$WATCH_DIR" -type f -name "*.jmd" | while read -r jmd_file; do
        jl_file="${jmd_file%.jmd}.jl"
        
        # Extract module name from the first markdown h1
        module_name=$(awk '/^# / {print substr($0, 3); exit}' "$jmd_file")
        
        # Check for spaces in the module name
        if [[ "$module_name" =~ \  ]]; then
            echo "Error: Module name (h1) '$module_name' contains spaces. Skipping $jmd_file."
            continue
        fi

        # Check if the .jmd file has changed
        if ! diff <(md5sum "$jmd_file") <(grep "$jmd_file" "$PREV_STATE_FILE") > /dev/null; then
            echo "Processing $jmd_file..."
            # Extract Julia code blocks and join them with \n\n
            awk -v module_name="$module_name" -v filename="$(basename "$jmd_file")" '
                BEGIN { 
                    in_block=0; 
                    print "# This file is auto-generated from " filename "." 
                    print "# Do not edit this file manually.\n" 
                    print "module " module_name "\n" 
                }
                /```julia/ { in_block=1; next }
                /```/ { in_block=0; print "" }
                in_block { print }
                END { print "end" }
            ' "$jmd_file" > "$jl_file"
        fi
    done

    # Remove .jl files for deleted .jmd files
    find "$WATCH_DIR" -type f -name "*.jl" | while read -r jl_file; do
        jmd_file="${jl_file%.jl}.jmd"
        if [ ! -f "$jmd_file" ]; then
            echo "$jmd_file not found. Deleting $jl_file."
            rm "$jl_file"
        fi
    done
}

# Save the initial state
find "$WATCH_DIR" -type f -name "*.jmd" -exec md5sum {} + > "$PREV_STATE_FILE"

echo "Watching $WATCH_DIR for changes..."

while true; do
    sleep 1 # Check every 2 seconds

    # Save the current state
    CURRENT_STATE=$(mktemp)
    find "$WATCH_DIR" -type f -name "*.jmd" -exec md5sum {} + > "$CURRENT_STATE"

    # Check if the current state is different from the previous state
    if ! diff "$PREV_STATE_FILE" "$CURRENT_STATE" > /dev/null; then
        run_task
        # Update the previous state
        mv "$CURRENT_STATE" "$PREV_STATE_FILE"
    else
        rm "$CURRENT_STATE"
    fi
done