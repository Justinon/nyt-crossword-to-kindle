import sys
from bs4 import BeautifulSoup
import html

def process_html(input_file):
    try:
        with open(input_file, 'r') as f:
            content = f.read()
            if not content.strip():
                raise ValueError("Input file is empty or contains only whitespace.")

            soup = BeautifulSoup(content, 'lxml')
            for img_tag in soup.find_all('img'):
                img_tag.decompose()  # Safely remove all <img> tags

            return soup.prettify()
    except IndexError as e:
        print(f"IndexError: {e}. Check if the input file is malformed. Full Content: {content}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error processing HTML content: {e}. Full Content: {content}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python process_html.py <input_file>", file=sys.stderr)
        sys.exit(1)

    input_file = sys.argv[1]
    processed_html = process_html(input_file)
    print(processed_html)