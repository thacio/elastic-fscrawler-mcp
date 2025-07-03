#!/bin/bash

# Python executor for Gemini CLI MCP
# Executes Python code safely

case "$1" in
  "run")
    # Execute Python code from argument
    if [ -n "$2" ]; then
      # Code provided as argument
      python3 -c "$2"
    else
      echo "Error: No code provided"
      exit 1
    fi
    ;;
  "file")
    # Execute Python file with optional arguments
    shift # Remove 'file' from arguments
    python3 "$@"
    ;;
  "version")
    # Get Python version
    python3 --version
    ;;
  "help")
    # Get help
    python3 --help
    ;;
  *)
    echo "Usage: $0 {run|file|version|help} [code/file] [args...]"
    echo "Examples:"
    echo "  $0 run 'print(\"Hello World\")'"
    echo "  $0 file script.py"
    echo "  $0 file script.py arg1 arg2"
    echo "  $0 version"
    exit 1
    ;;
esac