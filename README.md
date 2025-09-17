# nyt-crossword-to-kindle

Takes a NYT Crossword and sends it straight to your Kindle for your e-ink solving pleasure! Tried to make this as simple as possible so that even the layperson with technology can get to solving.

Starting as a basic, thrown together project for my wife, I wanted to make this available to the world for others to partake in. The NYTGames app is great, but there's nothing quite like writing the crosswords out on "paper".

## Requirements

Any technical requirements listed below will be walked through in the [tutorial video](#tutorial-video) *and* the [step-by-step instructions](#step-by-step-instructions) below.

- A tiny bit of patience
- A valid NYT subscription
- Docker (or any substitute like OrbStack) and `docker-compose`
- An email address (ideally a burner created specifically to send crosswords)

## Tutorial Video

LINK TUTORIAL HERE

## Step-by-Step Instructions

Follow these instructions in order to get to solving!

### Get Things Set Up

#### 1. Install Docker
This program uses something called *Docker*. Think of Docker as a way to run the program without messing up your computer.

- Install Docker Desktop:
  - [Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
  - [Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
  - [Linux](https://docs.docker.com/desktop/setup/install/linux/)

#### 2. Download the Program
1. [Click here to download the program](https://github.com/Justinon/nyt-crossword-to-kindle/archive/refs/heads/main.zip).
2. Unzip (extract) the zip file you downloaded.
   1. On Windows, use File Explorer
   2. On MacOS, use Finder
   3. On Linux...you know what you're doing
3. Enable viewing hidden files.
   1. [Windows](https://helpx.adobe.com/x-productkb/global/show-hidden-files-folders-extensions.html)
   2. On MacOS, press `CMD + Shift + .` in your Finder window
   3. On Linux...you know what you're doing
4. Inside that folder:
   - Find the file called `.env.example`
   - Make a copy of it and rename the copy to `.env`
   - Create a new folder called `downloads`

#### 3. Get Your NYTimes Login Cookies
This program needs proof that *you* have a New York Times subscription. That proof comes from your “cookies” (a little file your browser uses to remember you).

1. Install a browser extension that can export cookies. If you use Chrome, [this one works well](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc).
2. Log into [nytimes.com](https://nytimes.com).
3. Use the extension to export your cookies in “Netscape” format.
4. Save that file as `cookies.nyt.txt` and move it into the same folder where your `.env` file is.
   - (Optional) Compare it to the example file `cookies.sample.txt`—just to make sure it looks similar.

#### 4. (Optional, but Highly Recommended) Use a Throwaway Email
This program will send crosswords to your Kindle by email. That means it needs your email password. **For safety, don’t use your main email.**

- Create a new “burner” email just for this.
  - Example: `myburneremail123@gmail.com`
- You’ll use this address only for sending puzzles.

#### 5. Allow Emails to Your Kindle
Amazon requires you to give permission for who can send things to your Kindle.

1. Go to your [Amazon Kindle settings](https://www.amazon.com/gp/help/customer/display.html?nodeId=GX9XLEVV8G4DB28H).
2. Add your new burner email address as an approved sender.

#### 6. Fill in the `.env` File
Remember the `.env` file you created earlier? This file is where you tell the program about your setup.

1. Open up the file in a text editor.
   1. On Windows, use Notepad
   2. On MacOS, use TextEdit
   3. On Linux...you know what you're doing
2. Fill in the values. For each of the below, you only change the part **after the `=`**. 

   * **`DOWNLOADS_SYSTEM_PATH`** → Path to folder where you saved the project when you downloaded it.
      - Example (Mac/Linux): `~/Downloads/nyt-crossword-to-kindle`
      - Example (Windows): `C:\Users\YourName\Downloads\nyt-crossword-to-kindle`

   * **`COOKIE_FILE`** → Path to your `cookies.nyt.txt` file ([from earlier steps](#3-get-your-nytimes-login-cookies)).
      - Example: `~/Downloads/nyt-crossword-to-kindle/cookies.nyt.txt`

   * **`CROSSWORD_SENDER_EMAIL_ADDRESS_PREFIX`** → The part of your burner email before the `@`.
      - Example: if your email is `myburneremail123@gmail.com`, write `myburneremail123`.

   * **`CROSSWORD_SENDER_EMAIL_ADDRESS_DOMAIN`** → The part of your burner email after the `@`.
      - Example: `gmail.com`

   * **`CROSSWORD_SENDER_EMAIL_APP_PASSWORD`** → The password for your burner email.

   * **`KINDLE_EMAIL_ADDRESS`** → The special email address Amazon gave you for your Kindle
      ([find it here](https://www.amazon.com/sendtokindle/email)).

   * **`CROSSWORD_COMMAND_LINE_ARGUMENTS`** (Optional) → Extra options for customizing the crossword.
      - `--version [newspaper | games | big]` → how you want the crossword formatted. Defaults to newspaper if not specified.
        - Example: `--version newspaper` → classic crossword with previous day's solution
        - Example: `--version games` → puzzle on first page, its solution on next page
        - Example: `--version big` → full-page puzzle, clues on next page, solution on the last
      - `--date YYYY-MM-DD` → get a crossword from a specific date.
        - Example: `--date 2023-04-02` → April 2nd, 2023
      - `--from-date YYYY-MM-DD --to-date YYYY-MM-DD` → get all crosswords from the given date range. This combines all of them into a single PDF.
        - Example: `--from-date 2024-01-01 --to-date 2024-12-31` → All of 2024
      - `--multiple-pdfs` → when date range is specified, sends each as a separate PDF
      - `--disable-send` → only downloads the crossword(s)...does not send to your Kindle
    
      You can combine these options.
      
      Examples:
      - `--version big --date 1999-01-04`
        - Sends the big version of the crossword from January 4th, 1999 to your Kindle.
      - `--from-date 2021-08-01 --to-date 2021-08-31`
        - Sends all newspaper version crosswords from August 2021 (as a single PDF) to your Kindle.
      - `--disable-send --version games --date 1999-05-20`
        - Downloads games version of May 20th, 1999 crossword but does not send to Kindle

3. Compare against `.env.example` just to make sure it looks similar.

### Test It Out
Let's make sure it's all configured correctly:

1. Open a terminal window (on MacOS or Linux) or a PowerShell window (on Windows).
2. Use the terminal or PowerShell to navigate to the folder where you unzipped the code repository. For example:
   - On MacOS or Linux, type `cd ~/Downloads/nyt-crossword-to-kindle` (replace with your actual folder path).
   - On Windows, type `cd C:\Users\YourName\Downloads\nyt-crossword-to-kindle` (replace with your actual folder path).
3. Once you are in the correct folder, type the following command and press Enter:
     ```
     docker-compose build && docker-compose up
     ```
     This will run the program. If everything is successful, the output should resemble this:
     ```
     crossword-sender  | Sending file crossword-<DATE>-<VERSION>.pdf to kindle email address <KINDLE_EMAIL_ADDRESS>
     crossword-sender  | TLSv1.3 connection using TLSv1.3 (TLS_AES_256_GCM_SHA384)
     crossword-sender  | Send successful!

     crossword-sender exited with code 0
     ```
4. Now, check your Kindle. It may take a few minutes to appear.
