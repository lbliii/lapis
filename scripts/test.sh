#!/bin/bash

# Lapis Test Runner - Enhanced Developer Experience
# Beautiful, organized test output with proper formatting and colors

set -e

# ANSI color codes for beautiful output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[0;37m'
readonly GRAY='\033[0;90m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly RESET='\033[0m'

# Function to display help with nice formatting
show_help() {
  echo -e "${BOLD}${CYAN}"
  echo "╭─────────────────────────────────────────────────────────────╮"
  echo "│                    🧪 Lapis Test Runner                     │"
  echo "╰─────────────────────────────────────────────────────────────╯"
  echo -e "${RESET}"
  echo
  echo -e "${BOLD}USAGE:${RESET}"
  echo -e "  ${WHITE}$0${RESET} ${DIM}[options] [test_files...]${RESET}"
  echo
  echo -e "${BOLD}OPTIONS:${RESET}"
  echo -e "  ${GREEN}-v, --verbose${RESET}      Show detailed test output with full context"
  echo -e "  ${YELLOW}-q, --quiet${RESET}        Minimal output mode (dots and summary only)"
  echo -e "  ${MAGENTA}-p, --performance${RESET}  Include performance and benchmark tests"
  echo -e "  ${BLUE}-a, --all${RESET}          Run all test suites (unit + integration + perf)"
  echo -e "  ${CYAN}-h, --help${RESET}         Display this beautiful help message"
  echo
  echo -e "${BOLD}EXAMPLES:${RESET}"
  echo -e "  ${DIM}# Run unit tests with enhanced output${RESET}"
  echo -e "  ${WHITE}$0${RESET}"
  echo
  echo -e "  ${DIM}# Include performance tests${RESET}"
  echo -e "  ${WHITE}$0 -p${RESET}"
  echo
  echo -e "  ${DIM}# Verbose output for specific test${RESET}"
  echo -e "  ${WHITE}$0 -v spec/unit/config_spec.cr${RESET}"
  echo
  echo -e "  ${DIM}# Run everything${RESET}"
  echo -e "  ${WHITE}$0 -a${RESET}"
  echo
}

# Parse command line arguments
VERBOSE=false
QUIET=false
PERFORMANCE=false
ALL_TESTS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -q|--quiet)
      QUIET=true
      shift
      ;;
    -p|--performance)
      PERFORMANCE=true
      shift
      ;;
    -a|--all)
      ALL_TESTS=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      # Treat as test file arguments
      break
      ;;
  esac
done

# Function to print a beautiful header
print_header() {
  local title="$1"
  local subtitle="$2"

  echo -e "${BOLD}${CYAN}"
  echo "╭────────────────────────────────────────────────────────────────╮"
  echo "│                                                                │"
  echo "│  ▄▄▄█████▓▓█████   ██████ ▄▄▄█████▓ ██████                     │"
  echo "│  ▓  ██▒ ▓▒▓█   ▀ ▒██    ▒ ▓  ██▒ ▓▒▒██    ▒                     │"
  echo "│  ▒ ▓██░ ▒░▒███   ░ ▓██▄   ▒ ▓██░ ▒░░ ▓██▄                       │"
  echo "│  ░ ▓██▓ ░ ▒▓█  ▄   ▒   ██▒░ ▓██▓ ░   ▒   ██▒                    │"
  echo "│    ▒██▒ ░ ░▒████▒▒██████▒▒  ▒██▒ ░ ▒██████▒▒                    │"
  echo "│    ▒ ░░   ░░ ▒░ ░▒ ▒▓▒ ▒ ░  ▒ ░░   ▒ ▒▓▒ ▒ ░                    │"
  echo "│      ░     ░ ░  ░░ ░▒  ░ ░    ░    ░ ░▒  ░ ░                    │"
  echo "│    ░         ░   ░  ░  ░    ░      ░  ░  ░                      │"
  echo "│              ░  ░      ░                 ░                      │"
  echo "│                                                                │"
  echo "╰────────────────────────────────────────────────────────────────╯"
  echo -e "${RESET}"

  if [ -n "$title" ]; then
    echo -e "${BOLD}${WHITE}  $title${RESET}"
  fi
  if [ -n "$subtitle" ]; then
    echo -e "${DIM}  $subtitle${RESET}"
  fi
  echo
}

# Function to print section headers
print_section() {
  local title="$1"
  local icon="$2"
  echo -e "${BOLD}${BLUE}$icon $title${RESET}"
  echo -e "${GRAY}▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔${RESET}"
}

# Function to show configuration
show_config() {
  print_section "Configuration" "⚙️ "

  local mode_color=$GREEN
  local mode_text="Enhanced"
  if [ "$QUIET" = true ]; then
    mode_color=$YELLOW
    mode_text="Quiet"
  elif [ "$VERBOSE" = true ]; then
    mode_color=$MAGENTA
    mode_text="Verbose"
  fi

  echo -e "  ${BOLD}Output Mode:${RESET}      ${mode_color}$mode_text${RESET}"

  local perf_color=$RED
  local perf_text="Disabled"
  if [ "$PERFORMANCE" = true ]; then
    perf_color=$GREEN
    perf_text="Enabled"
  fi
  echo -e "  ${BOLD}Performance:${RESET}      ${perf_color}$perf_text${RESET}"

  local scope_color=$BLUE
  local scope_text="Unit Tests"
  if [ "$ALL_TESTS" = true ]; then
    scope_text="All Tests"
  elif [ $# -gt 0 ]; then
    scope_text="Custom: $*"
  fi
  echo -e "  ${BOLD}Test Scope:${RESET}       ${scope_color}$scope_text${RESET}"
  echo
}

# Function to hide compilation noise and show clean progress
run_with_clean_output() {
  local temp_file=$(mktemp)
  local start_time=$(date +%s)

  print_section "Compiling & Running Tests" "🔄"
  echo -e "${DIM}  Compiling Crystal code...${RESET}"

  # Run crystal spec and capture output
  if crystal spec "$@" > "$temp_file" 2>&1; then
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo -e "${GREEN}  ✓ Compilation successful${RESET} ${DIM}(${duration}s)${RESET}"
    echo

    print_section "Test Results" "📊"

    # Extract and display the actual test results (skip compilation noise)
    local in_results=false
    while IFS= read -r line; do
      # Skip compilation progress lines
      if [[ "$line" =~ ^\[.*\].*Codegen ]]; then
        continue
      fi
      # Skip semantic analysis lines
      if [[ "$line" =~ ^\[.*\].*Semantic ]]; then
        continue
      fi
      # Skip parse lines
      if [[ "$line" =~ ^\[.*\].*Parse ]]; then
        continue
      fi

      # Start showing output once we hit actual test results
      if [[ "$line" =~ ^[[:space:]]*$ ]] && [ "$in_results" = false ]; then
        in_results=true
        continue
      fi

      if [ "$in_results" = true ] || [[ "$line" =~ ^[.FP] ]] || [[ "$line" =~ Finished ]] || [[ "$line" =~ examples ]] || [[ "$line" =~ failures ]] || [[ "$line" =~ Failure ]]; then
        # Color code the output
        if [[ "$line" =~ ^[[:space:]]*$ ]]; then
          echo
        elif [[ "$line" =~ "Finished in" ]]; then
          echo -e "${BOLD}${GREEN}  ✨ $line${RESET}"
        elif [[ "$line" =~ "0 failures" ]]; then
          echo -e "${BOLD}${GREEN}  🎉 $line${RESET}"
        elif [[ "$line" =~ "failures" ]]; then
          echo -e "${BOLD}${RED}  ❌ $line${RESET}"
        elif [[ "$line" =~ "Failure:" ]]; then
          echo -e "${RED}  $line${RESET}"
        elif [[ "$line" =~ ^[[:space:]]*[0-9]+\) ]]; then
          echo -e "${YELLOW}  $line${RESET}"
        else
          echo -e "  ${line}"
        fi
      fi
    done < "$temp_file"

    rm "$temp_file"

    # Add a beautiful success footer
    echo
    echo -e "${BOLD}${GREEN}╭─────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${BOLD}${GREEN}│                    🎊 Tests Complete! 🎊                    │${RESET}"
    echo -e "${BOLD}${GREEN}╰─────────────────────────────────────────────────────────────╯${RESET}"

  else
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo -e "${RED}  ✗ Compilation failed${RESET} ${DIM}(${duration}s)${RESET}"
    echo

    print_section "Error Details" "❌"
    cat "$temp_file" | sed 's/^/  /'
    rm "$temp_file"

    echo
    echo -e "${BOLD}${RED}╭─────────────────────────────────────────────────────────────╮${RESET}"
    echo -e "${BOLD}${RED}│                    💥 Build Failed! 💥                     │${RESET}"
    echo -e "${BOLD}${RED}╰─────────────────────────────────────────────────────────────╯${RESET}"

    exit 1
  fi
}

# Configure environment
if [ "$PERFORMANCE" = true ]; then
  export LAPIS_INCLUDE_PERFORMANCE=1
fi

# Set up spec options based on mode
if [ "$QUIET" = true ]; then
  SPEC_OPTS="--no-color --time"
elif [ "$VERBOSE" = true ]; then
  SPEC_OPTS="--verbose --time --color"
else
  # Default: clean, informative output
  SPEC_OPTS="--time --color"
fi

# Determine test files to run
if [ "$ALL_TESTS" = true ]; then
  TEST_FILES="spec/"
elif [ $# -eq 0 ]; then
  # Default: run unit tests only
  TEST_FILES="spec/unit/"
else
  TEST_FILES="$@"
fi

# Clear screen and show beautiful header
clear
print_header "Lapis Test Suite" "Crystal-powered static site generator"

# Show configuration
show_config "$@"

# Run tests with enhanced output
run_with_clean_output $SPEC_OPTS $TEST_FILES
