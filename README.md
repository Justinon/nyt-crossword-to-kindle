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

### 1. Get It Ready

We need to get the program and install any prerequisites:

1. Install Docker Desktop:
   1. [Windows](https://docs.docker.com/desktop/setup/install/windows-install/)
   2. [MacOS](https://docs.docker.com/desktop/setup/install/mac-install/)
   3. [Linux](https://docs.docker.com/desktop/setup/install/linux/)
2. [Download this code repository](https://github.com/Justinon/nyt-crossword-to-kindle/archive/refs/heads/main.zip) and open the zip.
   1. Keep in mind where you stored this. We'll need to reference its location soon.
3. In that folder, copy the contents of `.env.example` into a new file called `.env`.
4. Get your NYTimes cookies:
   1. On your web browser, install any extension capable of exporting cookies. My recommendation if on Chrome is [this one](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc).
   2. In your web browser, login to https://nytimes.com and use the extension to export your NYTimes cookies in the Netscape format.
      1. Move this file into the unzipped folder (i.e., next to `.env`)
      2. **_\[OPTIONAL\]_** Check that your `cookies.txt` file resembles what you see in `cookies.sample.txt`.
5. **_\[OPTIONAL, BUT RECOMMENDED\]_** Create a new email address. This will be used to send crosswords to your Kindle.
   1. **_Do not use this email address for anything else other than sending crosswords, because you need to give this program its password. You and I both care about online safety so re-using your real email is highly, highly discouraged...but I can't stop you._**
6. [Allow your email address to send documents to your Kindle](https://www.amazon.com/gp/help/customer/display.html?nodeId=GX9XLEVV8G4DB28H).
7. Now it's [time to fill out the details](#the-env-file) in the `.env` file.

#### The .env File

This is where the bulk of the configuration for the program lies.

For each line, you'll see `<SOME_NAME>=<SOME_VALUE>`. We need to replace everything after the `=` for each line with your real information.

Let's cover each line one-by-one:

1. `DOWNLOADS_SYSTEM_PATH`
   1. Set everything after the `=` sign to be whatever the path to your downloaded folder is from when you downloaded the repository. This will resemble something like `~/Downloads/nyt-crossword-to-kindle` if on MacOS/Linux or `C:\Users\<Your Username>\Downloads` on Windows.
2. `COOKIE_FILE`
   1. Set everything after the `=` sign to be the path to the cookies file you got from the prior steps. This should be in the same folder as `DOWNLOADS_SYSTEM_PATH`...for example, `~/Downloads/nyt-crossword-to-kindle/cookies.txt`.
3. `CROSSWORD_SENDER_EMAIL_ADDRESS_PREFIX`
   1. Assuming you created a new email address, let's suppose `myburneremail123@gmail.com`, this value should be `myburneremail123`.
4. `CROSSWORD_SENDER_EMAIL_ADDRESS_DOMAIN`
   1. Depends on where you created your burner email address. If `myburneremail123@gmail.com` is the email address, this value should be `gmail.com`.
5. `CROSSWORD_SENDER_EMAIL_APP_PASSWORD`
   1. Should be the password to the burner email address.
6. `KINDLE_EMAIL_ADDRESS`
   1. The value should be the [email address specified in your Amazon settings](https://www.amazon.com/sendtokindle/email).
7. `CROSSWORD_COMMAND_LINE_ARGUMENTS`
   1. Customizations for how you want the crossword to be sent. If you're happy with the newspaper version, where solutions for the present crossword come the next day, simply remove the entire line.
      1. If you want the games edition of the crossword (a little bigger than newspaper, no previous solutions), then set: `--version games`. Includes solutions for the current puzzle on the next page of the PDF.
      2. For a fullscreen crossword with the next page being the clues, set `--version big`
   2. If you want to repeat the [Test It Out step](#2-test-it-out) manually to get a specific date's crossword, set `--date YYYY-MM-DD`. For example, to get the crossword from August 2nd, 2023, set to `--date 2023-08-02`.
   3. You can combine these configurations. For example, if you want the `big` crossword from January 4th, 1999, set the value to `--version big --date 1999-01-04`.

### 2. Test It Out
Let's make sure it's all configured correctly:

1. Open a terminal window (on MacOS or Linux) or a PowerShell window (on Windows).
2. Use the terminal or PowerShell to navigate to the folder where you unzipped the code repository. For example:
   - On MacOS or Linux, type `cd ~/Downloads/nyt-crossword-to-kindle` (replace with your actual folder path).
   - On Windows, type `cd C:\Users\YourName\Downloads\nyt-crossword-to-kindle` (replace with your actual folder path).
3. Once you are in the correct folder, type the following command and press Enter:
     ```
     docker-compose up
     ```
     This will run the program. If everything is successful, the output should resemble this:
     ```
     crossword-sender  | Sending file crossword-<DATE>-<VERSION>.pdf to kindle email address <KINDLE_EMAIL_ADDRESS>
     crossword-sender  | TLSv1.3 connection using TLSv1.3 (TLS_AES_256_GCM_SHA384)
     crossword-sender  | Send successful!

     crossword-sender exited with code 0
     ```
4. Now, check your Kindle. It may take a few minutes to appear.

### 3. Setup The Daily Automation

TODO

https://stackoverflow.com/questions/59123499/crontab-is-not-running-local-bin-script-catalina-bigsur