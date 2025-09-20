# nyt-crossword-to-kindle <!-- omit in toc -->

Takes NYT Crosswords and sends them straight to your Kindle for your e-ink solving pleasure! Tried to make this as simple as possible so that even the layperson with technology can get to solving.

Starting as a basic, thrown together project for my wife, I wanted to make this available to the world for others to partake in. The NYTGames app is great, but there's nothing quite like writing the crosswords out on "paper".

## Table of Contents <!-- omit in toc -->
- [Requirements](#requirements)
- [Tutorial Video](#tutorial-video)
- [Basic Setup Instructions](#basic-setup-instructions)
  - [1. Install Docker](#1-install-docker)
  - [2. Download the nyt-crossword-to-kindle Program](#2-download-the-nyt-crossword-to-kindle-program)
  - [3. Get Your NYTimes Login Cookies](#3-get-your-nytimes-login-cookies)
  - [4. (Optional, but Highly Recommended) Use a Throwaway Email](#4-optional-but-highly-recommended-use-a-throwaway-email)
  - [5. Allow Emails to Your Kindle](#5-allow-emails-to-your-kindle)
  - [6. Fill in the `.env` File](#6-fill-in-the-env-file)
  - [7. Test It Out](#7-test-it-out)
- [Customization](#customization)
  - [I want to experiment without sending to Kindle](#i-want-to-experiment-without-sending-to-kindle)
  - [I want my crosswords in a different format](#i-want-my-crosswords-in-a-different-format)
  - [I want to download a specific crossword](#i-want-to-download-a-specific-crossword)
  - [I want to download a lot of crosswords at once](#i-want-to-download-a-lot-of-crosswords-at-once)
  - [I want my daily crossword sent at a specific time each day](#i-want-my-daily-crossword-sent-at-a-specific-time-each-day)
- [Customization Examples](#customization-examples)
- [Troubleshooting](#troubleshooting)


## Requirements

Any technical requirements listed below will be walked through in the [tutorial video](#tutorial-video) *and* the [step-by-step instructions](#step-by-step-instructions) below.

- A tiny bit of patience
- A valid NYT subscription
- Docker (or any substitute like OrbStack)
- An email address (ideally a burner created specifically to send crosswords)

## Tutorial Video

LINK TUTORIAL HERE

## Basic Setup Instructions

Follow these instructions in order to get to solving!

### 1. Install Docker
This program uses something called *Docker*. While a massive oversimplification, think of Docker as a way to run pre-packaged computer programs mostly agnostic of the operating system you're on (Windows, MacOS, Linux, etc.).

- Install Docker Desktop:
  - [Windows](https://docs.docker.com/desktop/setup/install/windows-install/) (do not enable Windows containers)
  - [Mac](https://docs.docker.com/desktop/setup/install/mac-install/)
  - [Linux](https://docs.docker.com/desktop/setup/install/linux/)

### 2. Download the nyt-crossword-to-kindle Program
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

### 3. Get Your NYTimes Login Cookies
This program needs proof that *you* have a New York Times subscription. That proof comes from your “cookies” (a little file your browser uses to remember you).

1. Install a browser extension that can export cookies. If you use Chrome, [this one works well](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc).
2. Log into [nytimes.com](https://nytimes.com).
3. Use the extension to export your cookies in “Netscape” format.
4. Save that file as `cookies.nyt.txt` and move it into the same folder where your `.env` file and `downloads` folder is.
   - (Optional) Compare it to the example file `cookies.sample.txt`—just to make sure it looks similar.

### 4. (Optional, but Highly Recommended) Use a Throwaway Email
This program will send crosswords to your Kindle by email. That means it needs your email password. **For safety, don’t use your main email.**

- Create a new “burner” email just for this.
  - Example: `myburneremail123@gmail.com`
- You’ll use this address only for sending puzzles.

### 5. Allow Emails to Your Kindle
Amazon requires you to give permission for who can send things to your Kindle.

1. Go to your [Amazon Kindle settings](https://www.amazon.com/gp/help/customer/display.html?nodeId=GX9XLEVV8G4DB28H).
2. Add your new burner email address as an approved sender.

### 6. Fill in the `.env` File
This file is where you tell the program about your setup.

1. Open up the `.env` file in a text editor.
   1. On Windows, use Notepad
   2. On MacOS, use TextEdit
   3. On Linux...you know what you're doing
2. Replace the following `REQUIRED` values (**after the `=`**) with your real information:
   * **`CROSSWORD_SENDER_EMAIL_ADDRESS_PREFIX`** → The part of your burner email before the `@`.
   * **`CROSSWORD_SENDER_EMAIL_ADDRESS_DOMAIN`** → The part of your burner email after the `@`.
   * **`CROSSWORD_SENDER_EMAIL_APP_PASSWORD`** → The password for your burner email.
   * **`KINDLE_EMAIL_ADDRESS`** → The special email address Amazon gave you for your Kindle
      ([find it here](https://www.amazon.com/sendtokindle/email)).
3. Make sure to save the file.

### 7. Test It Out
Let's make sure it's all configured correctly:

1. Open a terminal window (on MacOS or Linux) or a PowerShell window (on Windows).
2. Use the terminal or PowerShell to navigate to the folder where you unzipped the code repository. For example:
   - On MacOS or Linux, type `cd ~/Downloads/nyt-crossword-to-kindle` (replace with your actual folder path).
   - On Windows, type `cd C:\Users\YourName\Downloads\nyt-crossword-to-kindle` (replace with your actual folder path).
3. Once you are in the correct folder, type the following command and press Enter:
     ```
     docker compose up --force-recreate
     ```
     This will run the program. If everything is successful, the output should resemble this:
     ```
     crossword-sender  | -----------------CROSSWORD SENDER STARTING-----------------
     crossword-sender  | Kindle email address: myawesomekindleemail@kindle.com
     crossword-sender  | Defaulting to today's date (2025-09-20) for puzzle...
     crossword-sender  | Refreshing cookies to ensure they will not expire...
     crossword-sender  | Cookies refreshed.
     crossword-sender  | Game version selected for date 2025-09-20
     crossword-sender  | Found puzzle for provided date 2025-09-20. Downloading.
     crossword-sender  | Successfully combined Puzzle with Solution. Crossword name is crossword-2025-09-20-Saturday-games.pdf
     crossword-sender  | Changing author metadata on PDF crossword-2025-09-20-Saturday-games.pdf
     crossword-sender  |     1 image files updated
     crossword-sender  | Sending file crossword-2025-09-20-Saturday-games.pdf to kindle email address myawesomekindleemail@kindle.com
     crossword-sender  | TLSv1.3 connection using TLSv1.3 (TLS_AES_256_GCM_SHA384)
     crossword-sender  | Send successful!
     crossword-sender  | -----------------CROSSWORD SENDER FINISHED-----------------
     crossword-sender  | 
     crossword-sender  | Will send your crossword every day at: 08:00 America/Los_Angeles time
     crossword-sender  | The current time is: Sep 20 2025, 08:01
     crossword-sender  | Next restart will be: Sep 21 2025, 08:00
     crossword-sender  | See you in 23 hours 59 minutes and 58 seconds......
     ```
4. Now, check your Kindle...It may take a few minutes to appear. If it doesn't, see [troubleshooting below](#troubleshooting).
5. Huzzah! You're done. By default, you'll get your morning crossword at 8am Eastern Time.
   * If you want to customize your options further, continue to [Customization](#customization).

## Customization

### I want to experiment without sending to Kindle

Good thinking! There is an option to simply download the crosswords to your machine.

Three steps needed: **Disable sending, experiment, and re-enable sending.**

1. Disable sending:
    * By default, `.env` has an entry like this:
      ```bash
      CROSSWORD_COMMAND_LINE_ARGUMENTS='--version games'
      ```

    * You can change it to use the `--disable-send` flag, for example:
      ```bash
      CROSSWORD_COMMAND_LINE_ARGUMENTS='--version games --disable-send'
      ```
    * Save the file.
2. Experiment:
   * Play around with the other [Customization options](#customization) in any combination.
     * NOTE: Make sure to keep the `--disable-send` flag.
   * Follow the [Test It Out instructions](#7-test-it-out) again.
   * Repeat experimenting as much as you'd like until satisfied.
3. Re-enable sending:
   * In `.env`, remove the `--disable-send` part of the `CROSSWORD_COMMAND_LINE_ARGUMENTS` variable.
   * Save the file.

### I want my crosswords in a different format
By default, your `.env` has an entry like this:
```bash
CROSSWORD_COMMAND_LINE_ARGUMENTS='--version games'
```

There are three options you can change it to:
- `--version games` → puzzle on first page, its solution on next page
- `--version newspaper` → classic printed crossword with previous day's solution
- `--version big` → full-page puzzle, clues on next page, solution on the last
  
Save the file. The next time your daily crossword sends, it'll be in the selected format.

### I want to download a specific crossword
Three steps needed: **Change your `.env`, re-run the program, and revert `.env` back.**

1. Change `.env`:
    * By default, it has an entry like this:
      ```bash
      CROSSWORD_COMMAND_LINE_ARGUMENTS='--version games'
      ```

    * You can change it to use the `--date YYYY-MM-DD` flag, for example:
      ```bash
      # If you want the crossword from April 20th, 1998:
      CROSSWORD_COMMAND_LINE_ARGUMENTS='--version games --date 1998-04-20'
      ```
    * Save the file.
2. Re-run the program:
   * Follow the [Test It Out instructions](#7-test-it-out) again.
3. Revert the `.env` changes:
   * Remove the `--date YYYY-MM-DD` part of the `CROSSWORD_COMMAND_LINE_ARGUMENTS` variable.
   * Save the file.

### I want to download a lot of crosswords at once
Follow the same [instructions for getting a specific crossword](#i-want-to-download-a-specific-crossword), except instead of `--date YYYY-MM-DD`, use `--from-date YYYY-MM-DD --to-date YYYY-MM-DD`.

For example:
```bash
# All crosswords in May 2005 as a single PDF:
CROSSWORD_COMMAND_LINE_ARGUMENTS='--version games --from-date 2005-05-01 --to-date 2005-05-31'
```

If you want all of those sent as separate PDFs, just add `--multiple-pdfs`:
```bash
# All crosswords in May 2005 as separate PDFs:
CROSSWORD_COMMAND_LINE_ARGUMENTS='--version games --from-date 2005-05-01 --to-date 2005-05-31 --multiple-pdfs'
```

### I want my daily crossword sent at a specific time each day
TODO

## Customization Examples
The following are `CROSSWORD_COMMAND_LINE_ARGUMENTS` examples:
- `--version big --date 1999-01-04`
  - Sends the big version of the crossword from January 4th, 1999 to your Kindle.
- `--version newspaper --from-date 2021-08-01 --to-date 2021-08-31`
  - Sends all newspaper version crosswords from August 2021 (as a single PDF) to your Kindle.
- `--version games --date 1999-05-20 --disable-send `
  - Downloads games version of May 20th, 1999 crossword but does not send to Kindle
- `--version big --from-date 2021-08-01 --to-date 2021-08-31 --multiple-pdfs --disable-send`
  - Downloads all big version crosswords from August 2021 (each as their own PDF) but does not send to your kindle.

## Troubleshooting
TODO


<!-- ## TODO:

   * **`CROSSWORD_DOWNLOADS_PATH`** → Path to folder where you saved the project when you downloaded it.
      - Example (Mac/Linux): `~/Downloads/nyt-crossword-to-kindle`
      - Example (Windows): `C:\Users\YourName\Downloads\nyt-crossword-to-kindle`

   * **`NYT_COOKIES_PATH`** → Path to your `cookies.nyt.txt` file ([from earlier steps](#3-get-your-nytimes-login-cookies)).
      - Example: `~/Downloads/nyt-crossword-to-kindle/cookies.nyt.txt` -->