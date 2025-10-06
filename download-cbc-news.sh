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
    local html_content="<html><head><meta charset=\"UTF-8\"><title>CBC News Headlines</title></head><body><h1>CBC News Headlines - $(date +'%Y-%m-%d')</h1>"
    
    source /opt/venv/bin/activate

    for url in "${CBC_RSS_URLS[@]}"; do
        echo "Fetching RSS feed from ${url}"
        local rss_feed
        rss_feed=$(curl --silent --show-error -H "Accept-Charset: utf-8" "${url}")

        echo "Processing RSS feed..."
        local feed_title
        feed_title=$(echo "${rss_feed}" | xmlstarlet sel -t -m "/rss/channel/title" -v . -n)
        html_content+="<h2>${feed_title}</h2><ul>"

        local count=0
        # Use xmlstarlet to parse the RSS feed and extract titles, links, and descriptions
        while IFS= read -r title && IFS= read -r link && IFS= read -r description; do
            if [ "$count" -ge 9 ]; then
                break
            fi
            count=$((count + 1))
            # Decode HTML entities in description
            description=$(python3 -c "import html, sys; print(html.unescape(sys.argv[1]))" "${description}")
            html_content+="<li><a href='${link}'>${title}</a><p>${description}</p></li>"
        done < <(echo "${rss_feed}" | xmlstarlet sel -t -m "//item" -v "title" -n -v "link" -n -v "description" -n)
        
        html_content+="</ul>"
    done
    deactivate

    html_content+="</body></html>"

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
    source /opt/venv/bin/activate
    echo "${html_content}" | weasyprint - "${OUTPUT_PDF_PATH}"
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