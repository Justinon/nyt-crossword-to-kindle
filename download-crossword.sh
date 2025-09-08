#!/usr/bin/env bash
set -eo pipefail

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
COOKIES_FILE_PATH="${SCRIPT_PATH}/cookies.nyt.txt"
DOWNLOADS_PATH="${SCRIPT_PATH}/downloads"

declare -a DATE_FLAGS

function verify_env_vars() {
    if [ ! -f "${COOKIES_FILE_PATH}" ]; then
        echo "NYT Cookie file not present at expected location ${COOKIES_FILE_PATH}. Exiting."
        exit 1
    fi

    if [ ! -d "${DOWNLOADS_PATH}" ]; then
        echo "Downloads directory not present at expected location ${DOWNLOADS_PATH}. Exiting."
        exit 1
    fi
    echo "Downloads path: ${DOWNLOADS_PATH}"

    if [ -z "${KINDLE_EMAIL_ADDRESS}" ]; then
        echo "Kindle email address not set in environment variable KINDLE_EMAIL_ADDRESS. Exiting."
        exit 1
    fi
    echo "Kindle email address: ${KINDLE_EMAIL_ADDRESS}"
}

function parse_critical_flags() {
    IS_LINUX=false
    while [ $# -gt 0 ]; do
        case $1 in
            -l | --linux)
                IS_LINUX=true
                ;;
        esac
        shift
    done

    set_date_flags_by_os
}

function parse_optional_flags() {
    while [ $# -gt 0 ]; do
        case $1 in
            -v | --version)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo "Value not specified for --version." >&2
                    exit 1
                else
                    CROSSWORD_VERSION="$2"
                fi
                shift
                ;;
            -d | --disable-send)
                echo 'Sending detected as disabled. Will only download the puzzle.'
                DISABLE_SEND=true
                ;;
            --from-date)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo "Value not specified for --from-date." >&2
                    exit 1
                else
                    CROSSWORD_FROM_DATE="$2"
                    local err_msg=$(validate_flags_date_format "${CROSSWORD_FROM_DATE}")
                    if [ ! "${err_msg}" = "" ]; then
                        echo "--from-date value is invalid: ${err_msg}"
                    fi
                fi
                shift
                ;;
            --to-date)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo "Value not specified for --to-date." >&2
                    exit 1
                else
                    CROSSWORD_TO_DATE="$2"
                    local err_msg=$(validate_flags_date_format "${CROSSWORD_TO_DATE}")
                    if [ ! "${err_msg}" = "" ]; then
                        echo "--to-date value is invalid: ${err_msg}"
                    fi
                fi
                shift
                ;;
            --date)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo "Value not specified for --date." >&2
                    exit 1
                else
                    CROSSWORD_EXACT_DATE="$2"
                    local err_msg=$(validate_flags_date_format "${CROSSWORD_EXACT_DATE}")
                    if [ ! "${err_msg}" = "" ]; then
                        echo "--date value is invalid: ${err_msg}"
                    fi
                fi
                shift
                ;;
        esac
        shift
    done

    set_flag_defaults
}

function parse_flags() {
    parse_critical_flags $@
    parse_optional_flags $@
}

function set_flag_defaults() {
    if [ -z "${CROSSWORD_EXACT_DATE}" ]; then
        echo "Defaulting to today's date for puzzle..."
        CROSSWORD_EXACT_DATE=$(date +"%Y-%m-%d")
    fi

    if [ -z "${CROSSWORD_VERSION}" ]; then
        echo "Defaulting to newspaper version..."
        CROSSWORD_VERSION='newspaper'
    fi
}

function set_date_flags_by_os() {
    if [ "${IS_LINUX}" = "true" ]; then
        DATE_FLAGS+=(-d)
    else 
        DATE_FLAGS+=(-j -f "%Y-%m-%d")
    fi
}

function validate_flags_date_format() {
    local dateValue="$1"

    if [ ! "${dateValue}" = $(date "${DATE_FLAGS[@]}" "${dateValue}" "+%Y-%m-%d") ]; then
        echo "Provided date \"${dateValue}\" must be in format \"YYYY-MM-DD\"."
        exit 1
    fi
}

# TODO: Ensure both are actually set
function validate_flags_date_range() {
    local from_date="$1"
    local to_date="$2"

    # convert both to seconds since epoch
    local fromTime=$(date "${DATE_FLAGS[@]}" "${from_date}" +%s)
    local toTime=$(date "${DATE_FLAGS[@]}" "${to_date}" +%s)

    # absolute difference in days
    local diff_days=$(( (fromTime > toTime ? fromTime - toTime : toTime - fromTime) / 86400 ))

    if [ "$diff_days" -le 60 ]; then
        echo "Dates are within 2 months (~60 days)."
    else
        echo "Dates are more than 2 months apart."
        exit 1
    fi
}

function validate_flag_composition() {
    validate_flags_date_range "${CROSSWORD_FROM_DATE}" "${CROSSWORD_TO_DATE}"
}

function refresh_session_token() {
    echo 'Refreshing cookies to ensure they will not expire...'
    local nyt_refresh_url='https://a.nytimes.com/svc/nyt/data-layer'

    local cookies=$(curl --silent --cookie-jar - -o /dev/null -b "${COOKIES_FILE_PATH}" "${nyt_refresh_url}")
    printf '%s\n' "$cookies" > $COOKIES_FILE_PATH

    echo 'Cookies refreshed.'
}

# Obtains the newspaper version of the puzzle from today's date
function get_puzzle_newspaper_version() {
    local translated_date=$(date "${DATE_FLAGS[@]}" "${CROSSWORD_EXACT_DATE}" +"%b%d%y")

    # Format specifier must be in, for example, Jan0125 format for January 1st, 2025 puzzle.
    local NYT_CROSSWORD_PUZZLE_NEWSPAPER_PDF_PATH='https://www.nytimes.com/svc/crosswords/v2/puzzle/print/%s.pdf'

    local DAILY_PUZZLE_PDF_PATH=$(printf "${NYT_CROSSWORD_PUZZLE_NEWSPAPER_PDF_PATH}" "${translated_date}")

    local day_of_the_week=$(date "${DATE_FLAGS[@]}" "${CROSSWORD_EXACT_DATE}" +"%A")

    # Get puzzle pdf
    OUTPUT_CROSSWORD_FILE_PATH="${DOWNLOADS_PATH}/crossword-${CROSSWORD_EXACT_DATE}-${day_of_the_week}-newspaper.pdf"
    curl -b "${COOKIES_FILE_PATH}" "${DAILY_PUZZLE_PDF_PATH}" --output "${OUTPUT_CROSSWORD_FILE_PATH}"

    echo "Successfully acquired newspaper version. Crossword name is $(basename ${OUTPUT_CROSSWORD_FILE_PATH})"
}

# Obtains the game version of the puzzle that's more recently available (can be ahead of today's current date)
function get_puzzle_game_version() {
    local is_big=${1:-false}
    local nyt_crosswords_puzzle_json_path='https://www.nytimes.com/svc/crosswords/v3/puzzles.json'

    # Format specifier must be the puzzle ID
    local nyt_crossword_puzzle_games_pdf_path='https://www.nytimes.com/svc/crosswords/v2/puzzle/%s.pdf'
    test "${is_big}" = "false" || nyt_crossword_puzzle_games_pdf_path="${nyt_crossword_puzzle_games_pdf_path}?large_print=true"
    local nyt_crossword_puzzle_games_ans_pdf_path='https://www.nytimes.com/svc/crosswords/v2/puzzle/%s.ans.pdf'

    # Get puzzle info
    local puzzle_info=$(curl -b "${COOKIES_FILE_PATH}" "${nyt_crosswords_puzzle_json_path}?publish_type=daily&sort_order=asc&sort_by=print_date&date_start=${CROSSWORD_EXACT_DATE}&date_end=${CROSSWORD_EXACT_DATE}&limit=1")
    local puzzid=$(echo "${puzzle_info}" | jq '.results[0].puzzle_id' )
    local puzzle_print_date=$(echo "${puzzle_info}" | jq -r '.results[0].print_date')

    # Structure pdf path and intended output file name
    local puzzle_pdf_path_rendered=$(printf "${nyt_crossword_puzzle_games_pdf_path}" "${puzzid}")
    local puzzle_ans_pdf_path_rendered=$(printf "${nyt_crossword_puzzle_games_ans_pdf_path}" "${puzzid}")
    local day_of_the_week=$(date "${DATE_FLAGS[@]}" "${puzzle_print_date}" +"%A")
    local date_today_crossword_name="${puzzle_print_date}-${day_of_the_week}"

    # Get puzzle pdf
    local crossword_file_path="${DOWNLOADS_PATH}/crossword-${date_today_crossword_name}-games-puzzle.pdf"
    curl -b "${COOKIES_FILE_PATH}" "${puzzle_pdf_path_rendered}" --output "${crossword_file_path}"

    # Get solution pdf
    local ans_file_path="${DOWNLOADS_PATH}/crossword-${date_today_crossword_name}-games-solution.pdf"
    curl -b "${COOKIES_FILE_PATH}" "${puzzle_ans_pdf_path_rendered}" --output "${ans_file_path}"

    # Combine into final pdf
    local crossword_name="crossword-${date_today_crossword_name}-games"
    test "${is_big}" = "false" || crossword_name="${crossword_name}-big"
    OUTPUT_CROSSWORD_FILE_PATH="${DOWNLOADS_PATH}/${crossword_name}.pdf"
    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="${OUTPUT_CROSSWORD_FILE_PATH}" "${crossword_file_path}" "${ans_file_path}"

    rm "${crossword_file_path}" "${ans_file_path}"
    echo "Successfully combined Puzzle with Solution. Crossword name is $(basename ${OUTPUT_CROSSWORD_FILE_PATH})"
}

# BEGIN MAIN EXECUTION
verify_env_vars
parse_flags $@
refresh_session_token

# Obtain puzzle
case "${CROSSWORD_VERSION}" in
    "newspaper")
        echo 'Newspaper version selected'
        get_puzzle_newspaper_version
        ;;
    "games")
        echo 'Game version selected'
        get_puzzle_game_version
        ;;
    "big")
        echo 'Big game version selected'
        get_puzzle_game_version true
        ;;
    *)
        echo "Invalid crossword version: ${CROSSWORD_VERSION}"
        exit 1
        ;;
esac

# Add Author (converts from Unknown to NYT)
echo 'Changing author metadata on PDF'
exiftool -overwrite_original_in_place -title="" -author="The New York Times" "${OUTPUT_CROSSWORD_FILE_PATH}"

# Send to Kindle
if [ -z "${DISABLE_SEND}" ]; then
    echo "Sending file $(basename ${OUTPUT_CROSSWORD_FILE_PATH}) to kindle email address ${KINDLE_EMAIL_ADDRESS}"
    echo "You crossword is here!" | mutt -s "NYT Crossword" -a "${OUTPUT_CROSSWORD_FILE_PATH}" -- "${KINDLE_EMAIL_ADDRESS}"
    echo 'Send successful!'
fi