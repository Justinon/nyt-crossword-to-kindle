#!/usr/bin/env bash
set -eo pipefail

SCRIPT_PATH="$(dirname "$(readlink -f "$0")")"
DOWNLOADS_INTERNAL_PATH="${SCRIPT_PATH}/downloads"
CBC_RSS_URLS=(
    "https://www.cbc.ca/webfeed/rss/rss-topstories"
    "https://www.cbc.ca/webfeed/rss/rss-world"
    "https://www.cbc.ca/webfeed/rss/rss-canada"
    "https://www.cbc.ca/webfeed/rss/rss-politics"
    "https://www.cbc.ca/webfeed/rss/rss-business"
    "https://www.cbc.ca/webfeed/rss/rss-health"
    "https://www.cbc.ca/webfeed/rss/rss-arts"
    "https://www.cbc.ca/webfeed/rss/rss-technology"
    "https://www.cbc.ca/webfeed/rss/rss-canada-novascotia"
)
OUTPUT_PDF_PATH="${DOWNLOADS_INTERNAL_PATH}/cbc-news-$(date +'%Y-%m-%d').pdf"

function verify_env_vars() {
    if [ ! -d "${DOWNLOADS_INTERNAL_PATH}" ]; then
        echo "Downloads directory not present at expected location ${DOWNLOADS_INTERNAL_PATH}. Exiting."
        exit 1
    fi

    if [ -z "${KINDLE_EMAIL_ADDRESS}" ]; then
        echo "Kindle email address not set in environment variable KINDLE_EMAIL_ADDRESS. Exiting."
        exit 1
    fi

    if [ -n "${CBC_RSS_FEEDS}" ]; then
        IFS="," read -r -a CBC_RSS_URLS <<< "${CBC_RSS_FEEDS}"
        echo "Using custom RSS feeds from environment variable CBC_RSS_FEEDS."
    fi

    if [ -n "${CBC_OUTPUT_PATH}" ]; then
        OUTPUT_PDF_PATH="${CBC_OUTPUT_PATH}/cbc-news-$(date +'%Y-%m-%d').pdf"
        echo "Using custom output path from environment variable CBC_OUTPUT_PATH."
    fi
}

function fetch_and_process_rss() {
    echo "Fetching and processing RSS feeds using Python script..."
    source /opt/venv/bin/activate
    
    # The process_rss.py script will output the full initial HTML.
    local html_content
    html_content=$(python3 /crosswords/process_rss.py "${CBC_RSS_URLS[@]}")

    # Write HTML content to a dedicated temporary directory
    local temp_html_file=$(mktemp /crosswords/tmp/cbc-news-XXXXXX.html)
    echo "${html_content}" > "${temp_html_file}"

    # Debugging: Log the temporary file path and permissions
    echo "Temporary HTML file path: ${temp_html_file}" >&2
    ls -l "$(dirname ${temp_html_file})" >&2

    # Validate the input file before processing
    if [ ! -s "${temp_html_file}" ]; then
        echo "Error: Temporary HTML file is empty or does not exist." >&2
        rm -f "${temp_html_file}"
        exit 1
    fi

    # Process the HTML content using the standalone Python script
    html_content=$(python3 /crosswords/process_html.py "${temp_html_file}")

    # Remove the temporary file immediately after processing
    rm -f "${temp_html_file}"

    echo "Converting news to PDF..."
    # Write the final HTML to a new temporary file to be passed to weasyprint
    local final_html_file=$(mktemp /crosswords/tmp/final-cbc-news-XXXXXX.html)
    echo "${html_content}" > "${final_html_file}"

    weasyprint "${final_html_file}" "${OUTPUT_PDF_PATH}"
    
    # Clean up the final HTML file
    rm -f "${final_html_file}"

    deactivate
    echo "Successfully created PDF: ${OUTPUT_PDF_PATH}"
}

function send_to_kindle() {
    local pdf_path="${1}"
    local pdf_name=$(basename "${pdf_path}")

    if [ -z "${DISABLE_SEND}" ]; then
        echo "Sending file ${pdf_name} to kindle email address ${KINDLE_EMAIL_ADDRESS}"
        echo "Today's CBC News headlines are here!" | mutt -s "CBC News Headlines" -a "${pdf_path}" -- "${KINDLE_EMAIL_ADDRESS}"
        echo 'Send successful!'
    else
        echo "Sending detected as disabled. Will not send file ${pdf_name} to kindle email address ${KINDLE_EMAIL_ADDRESS}"
    fi
}

function parse_flags() {
    while [ $# -gt 0 ]; do
        case $1 in
            -d | --disable-send)
                echo 'Sending detected as disabled. Will only download the news.'
                DISABLE_SEND=true
                ;;
        esac
        shift
    done
}

# BEGIN MAIN EXECUTION
echo -e "
-----------------CBC NEWS SENDER STARTING-----------------"

verify_env_vars
parse_flags "$@"
fetch_and_process_rss
send_to_kindle "${OUTPUT_PDF_PATH}"

echo -e "-----------------CBC NEWS SENDER FINISHED-----------------
"