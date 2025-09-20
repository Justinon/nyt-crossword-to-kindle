#!/usr/bin/env bash
set -eo pipefail

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
COOKIES_FILE_INTERNAL_PATH="${SCRIPT_PATH}/cookies.nyt.txt"
DOWNLOADS_INTERNAL_PATH="${SCRIPT_PATH}/downloads"

function verify_env_vars() {
    if [ ! -f "${COOKIES_FILE_INTERNAL_PATH}" ]; then
        echo "NYT Cookie file not present at expected location ${COOKIES_FILE_INTERNAL_PATH}. Exiting."
        exit 1
    fi

    if [ ! -d "${DOWNLOADS_INTERNAL_PATH}" ]; then
        echo "Downloads directory not present at expected location ${DOWNLOADS_INTERNAL_PATH}. Exiting."
        exit 1
    fi

    if [ -z "${KINDLE_EMAIL_ADDRESS}" ]; then
        echo "Kindle email address not set in environment variable KINDLE_EMAIL_ADDRESS. Exiting."
        exit 1
    fi
    echo "Kindle email address: ${KINDLE_EMAIL_ADDRESS}"
}

function parse_flags() {
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
                    local crossword_exact_date="$2"
                    CROSSWORD_FROM_DATE="${crossword_exact_date}"
                    CROSSWORD_TO_DATE="${crossword_exact_date}"
                    local err_msg=$(validate_flags_date_format "${crossword_exact_date}")
                    if [ ! "${err_msg}" = "" ]; then
                        echo "--date value is invalid: ${err_msg}"
                    fi
                fi
                shift
                ;;
            -m | --multiple-pdfs)
                echo 'Will ensure each puzzle (w/ solution if applicable with type) is in its own PDF.'
                MERGE_MULTIPLE_PDFS=false
                ;;
        esac
        shift
    done

    validate_date_flags_paired
    set_flag_defaults
}

function validate_date_flags_paired() {
    # Check that either both CROSSWORD_FROM_DATE and CROSSWORD_TO_DATE are set, or neither are set.
    if { [ -n "${CROSSWORD_FROM_DATE}" ] && [ -z "${CROSSWORD_TO_DATE}" ]; } || \
       { [ -z "${CROSSWORD_FROM_DATE}" ] && [ -n "${CROSSWORD_TO_DATE}" ]; }; then
        echo "Error: Both --from-date and --to-date must be specified together, or neither."
        exit 1
    fi
}

function set_flag_defaults() {
    if [ -z "${CROSSWORD_FROM_DATE}" ] && [ -z "${CROSSWORD_TO_DATE}" ]; then
        local crossword_exact_date=$(TZ=${TZ} date +"%Y-%m-%d")
        echo "Defaulting to today's date (${crossword_exact_date}) for puzzle..."
        CROSSWORD_FROM_DATE="${crossword_exact_date}"
        CROSSWORD_TO_DATE="${crossword_exact_date}"
    fi

    if [ -z "${CROSSWORD_VERSION}" ]; then
        echo "Defaulting to newspaper version..."
        CROSSWORD_VERSION='newspaper'
    fi
 
    if [ "${CROSSWORD_FROM_DATE}" = "${CROSSWORD_TO_DATE}" ]; then
        # Skip the merging into a new PDF phase
        MERGE_MULTIPLE_PDFS=false
    fi

    if [ -z "${MERGE_MULTIPLE_PDFS}" ]; then
        echo "Defaulting to consolidation of all puzzles into a single PDF..."
        MERGE_MULTIPLE_PDFS=true
    fi
}

function validate_flags_date_format() {
    local dateValue="$1"

    if [ ! "${dateValue}" = $(date -d "${dateValue}" "+%Y-%m-%d") ]; then
        echo "Provided date \"${dateValue}\" must be in format \"YYYY-MM-DD\"."
        exit 1
    fi
}

# TODO: Ensure both are actually set
function validate_flags_date_range() {
    local from_date="$1"
    local to_date="$2"

    # convert both to seconds since epoch
    local fromTime=$(date -d "${from_date}" +%s)
    local toTime=$(date -d "${to_date}" +%s)

    # absolute difference in days
    local diff_days=$(( (fromTime > toTime ? fromTime - toTime : toTime - fromTime) / 86400 ))

    if [ "$diff_days" -le 60 ]; then
        echo "Dates are within 2 months (~60 days)."
    else
        echo "Dates are more than 2 months apart."
        exit 1
    fi
}

# TODO: Call this somewhere
function validate_flag_composition() {
    validate_flags_date_range "${CROSSWORD_FROM_DATE}" "${CROSSWORD_TO_DATE}"
}

function refresh_session_token() {
    echo 'Refreshing cookies to ensure they will not expire...'
    local nyt_refresh_url='https://a.nytimes.com/svc/nyt/data-layer'

    local cookies=$(curl --silent --show-error --cookie-jar - -o /dev/null -b "${COOKIES_FILE_INTERNAL_PATH}" "${nyt_refresh_url}")
    printf '%s\n' "$cookies" > $COOKIES_FILE_INTERNAL_PATH

    echo 'Cookies refreshed.'
}

function get_day_of_the_week() {
    # YYYY-MM-DD format
    local date="${1}"
    echo $(date -d "${date}" +"%A")
}

# TODO: Rename transient to something else?
function get_transient_pdf_crossword_file_path() {
    local day_of_the_week=$(get_day_of_the_week "${CROSSWORD_EXACT_DATE}")
    local crossword_name="crossword-${CROSSWORD_EXACT_DATE}-${day_of_the_week}-${CROSSWORD_VERSION}"

    if [ "${MERGE_MULTIPLE_PDFS}" = "true" ]; then
        echo "${DOWNLOADS_INTERNAL_PATH}/${crossword_name}.transient.pdf"
    else
        echo "${DOWNLOADS_INTERNAL_PATH}/${crossword_name}.pdf"
    fi
}

function get_combined_dates_pdf_file_path() {
    local day_of_the_week=$(get_day_of_the_week "${CROSSWORD_FROM_DATE}")
    test "${CROSSWORD_FROM_DATE}" = "${CROSSWORD_TO_DATE}" \
        && local date_param="${CROSSWORD_FROM_DATE}-${day_of_the_week}" \
        || local date_param="(${CROSSWORD_FROM_DATE})-(${CROSSWORD_TO_DATE})"
    echo "${DOWNLOADS_INTERNAL_PATH}/crossword-${date_param}-${CROSSWORD_VERSION}.pdf"
}

function generate_combined_dates_pdf() {
    local crosswords_to_combine_file_path="${1}"
    local remove_source_file="${2:-true}"
    local final_pdf_path="$(get_combined_dates_pdf_file_path)"

    local to_append_basename="$(basename ${crosswords_to_combine_file_path})"
    echo "Appending crosswords in ${to_append_basename} to combined PDF at path ${final_pdf_path}"...
    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="${final_pdf_path}" @${crosswords_to_combine_file_path}
    echo "Successfully appended crosswords from file ${to_append_basename} to combined PDF."

    if [ "${remove_source_file}" = "true" ]; then
        echo "Removing temporary crossword file ${crosswords_to_combine_file_path}..."
        xargs rm -f < "${crosswords_to_combine_file_path}"
        echo "Successfully removed temporary crossword file."
    fi
    rm -f "${crosswords_to_combine_file_path}"
}

# Obtains the newspaper version of the puzzle from today's date
function get_puzzle_newspaper_version() {
    local translated_date=$(date -d "${CROSSWORD_EXACT_DATE}" +"%b%d%y")

    # Format specifier must be in, for example, Jan0125 format for January 1st, 2025 puzzle.
    local nyt_crossword_puzzle_newspaper_pdf_path='https://www.nytimes.com/svc/crosswords/v2/puzzle/print/%s.pdf'

    local daily_puzzle_pdf_path=$(printf "${nyt_crossword_puzzle_newspaper_pdf_path}" "${translated_date}")

    local day_of_the_week=$(get_day_of_the_week "${CROSSWORD_EXACT_DATE}")

    # Get puzzle pdf
    OUTPUT_CROSSWORD_FILE_PATH="$(get_transient_pdf_crossword_file_path)"
    curl --silent --show-error -b "${COOKIES_FILE_INTERNAL_PATH}" "${daily_puzzle_pdf_path}" --output "${OUTPUT_CROSSWORD_FILE_PATH}"

    # Verify puzzle for the passed in date exists
    local is_valid_puzzle=$(jq . "${OUTPUT_CROSSWORD_FILE_PATH}" >/dev/null 2>&1 && echo false || echo true)
    test "${is_valid_puzzle}" = "false" \
        && echo "ERROR: Puzzle for date ${CROSSWORD_EXACT_DATE} not found. Not yet released? Exiting." \
        && rm -f "${OUTPUT_CROSSWORD_FILE_PATH}" \
        && exit 1 \
        || echo "Found puzzle for provided date ${CROSSWORD_EXACT_DATE}. Downloading."

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
    local puzzle_info=$(curl --silent --show-error -b "${COOKIES_FILE_INTERNAL_PATH}" "${nyt_crosswords_puzzle_json_path}?publish_type=daily&sort_order=asc&sort_by=print_date&date_start=${CROSSWORD_EXACT_DATE}&date_end=${CROSSWORD_EXACT_DATE}&limit=1")
    local puzzle_info_results=$(echo "${puzzle_info}" | jq '.results')

    # Verify puzzle for the passed in date exists
    local is_valid_puzzle=$(test "${puzzle_info_results}" = "null" && echo false || echo true)
    test "${is_valid_puzzle}" = "false" \
        && echo "ERROR: Puzzle for date ${CROSSWORD_EXACT_DATE} not found. Not yet released? Exiting." \
        && exit 1 \
        || echo "Found puzzle for provided date ${CROSSWORD_EXACT_DATE}. Downloading."

    local puzzid=$(echo "${puzzle_info_results}" | jq '.[0].puzzle_id' )

    # Structure pdf path and intended output file name
    local puzzle_pdf_path_rendered=$(printf "${nyt_crossword_puzzle_games_pdf_path}" "${puzzid}")
    local puzzle_ans_pdf_path_rendered=$(printf "${nyt_crossword_puzzle_games_ans_pdf_path}" "${puzzid}")

    # Get puzzle pdf
    local crossword_file_path="${DOWNLOADS_INTERNAL_PATH}/crossword-${CROSSWORD_EXACT_DATE}-games-puzzle.pdf"
    curl --silent --show-error -b "${COOKIES_FILE_INTERNAL_PATH}" "${puzzle_pdf_path_rendered}" --output "${crossword_file_path}"

    # Get solution pdf
    local ans_file_path="${DOWNLOADS_INTERNAL_PATH}/crossword-${CROSSWORD_EXACT_DATE}-games-solution.pdf"
    curl --silent --show-error -b "${COOKIES_FILE_INTERNAL_PATH}" "${puzzle_ans_pdf_path_rendered}" --output "${ans_file_path}"

    # Combine into final pdf
    OUTPUT_CROSSWORD_FILE_PATH="$(get_transient_pdf_crossword_file_path)"
    gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress -sOutputFile="${OUTPUT_CROSSWORD_FILE_PATH}" "${crossword_file_path}" "${ans_file_path}"

    rm "${crossword_file_path}" "${ans_file_path}"
    echo "Successfully combined Puzzle with Solution. Crossword name is $(basename ${OUTPUT_CROSSWORD_FILE_PATH})"
}

function send_to_kindle() {
    local output_crossword_file_path="${1}"
    local crossword_name=$(basename "${output_crossword_file_path}")

    # Add Author (converts from Unknown to NYT)
    echo "Changing author metadata on PDF ${crossword_name}"
    exiftool -overwrite_original_in_place -title="" -author="The New York Times" "${output_crossword_file_path}"

    # Send to Kindle
    if [ -z "${DISABLE_SEND}" ]; then
        echo "Sending file ${crossword_name} to kindle email address ${KINDLE_EMAIL_ADDRESS}"
        echo "Your crossword is here!" | mutt -s "NYT Crossword" -a "${output_crossword_file_path}" -- "${KINDLE_EMAIL_ADDRESS}"
        echo 'Send successful!'
    else
        echo "Sending detected as disabled. Will not send file ${crossword_name} to kindle email address ${KINDLE_EMAIL_ADDRESS}"
    fi
}

# BEGIN MAIN EXECUTION
echo -e "\n-----------------CROSSWORD SENDER STARTING-----------------"

verify_env_vars
parse_flags $@
refresh_session_token

# Loop over date range
tmp_file_paths="/tmp/files"
current_date="${CROSSWORD_FROM_DATE}"
while [[ "${current_date}" < "${CROSSWORD_TO_DATE}" || "${current_date}" == "${CROSSWORD_TO_DATE}" ]]; do
    CROSSWORD_EXACT_DATE="${current_date}"

    # Obtain puzzle
    case "${CROSSWORD_VERSION}" in
        "newspaper")
            echo "Newspaper version selected for date ${CROSSWORD_EXACT_DATE}"
            get_puzzle_newspaper_version
            ;;
        "games")
            echo "Game version selected for date ${CROSSWORD_EXACT_DATE}"
            get_puzzle_game_version
            ;;
        "big")
            echo "Big game version selected for date ${CROSSWORD_EXACT_DATE}"
            get_puzzle_game_version true
            ;;
        *)
            echo "Invalid crossword version: ${CROSSWORD_VERSION}"
            exit 1
            ;;
    esac

    if [ "${MERGE_MULTIPLE_PDFS}" = "false" ]; then
        send_to_kindle "${OUTPUT_CROSSWORD_FILE_PATH}"
    else
        echo "${OUTPUT_CROSSWORD_FILE_PATH}" >> "${tmp_file_paths}"
    fi

    # Increment date
    current_date=$(date -d "${CROSSWORD_EXACT_DATE} +1 day" +"%Y-%m-%d")
done

if [ "${MERGE_MULTIPLE_PDFS}" = "true" ]; then
    generate_combined_dates_pdf "${tmp_file_paths}"
    send_to_kindle "$(get_combined_dates_pdf_file_path)"
fi

echo -e "-----------------CROSSWORD SENDER FINISHED-----------------\n"