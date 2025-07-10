
#!/usr/bin/env python3
import sys
import time
import random
import os
import traceback
from datetime import datetime
import pytz
import smtplib
from email.mime.text import MIMEText
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException

# --- Environment variables ---
USERNAME    = os.environ.get("USERNAME", "SAMPLE_USERNAME")
PASSWORD    = os.environ.get("PASSWORD", "SAMPLE_PASSWORD")
POS_ID      = os.environ.get("POS_ID", "000000")
GMAIL_USER  = os.environ.get("GMAIL_USER", "CHANGE_ME@CHANGE_ME.com")  # <===ADMINISTRATOR'S EMAIL. SEE README.md
GMAIL_PASS  = os.environ.get("GMAIL_PASS", "CHANGE_ME")                # <===ADMINISTRATOR'S EMAIL. SEE README.md
SECOND_EMAIL = os.environ.get("GMAIL_SECOND_USER")

# --- Paths & Recipients ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SUCCESS_LOG_FILE = os.path.join(SCRIPT_DIR, "success.log")
ERROR_LOG_FILE   = os.path.join(SCRIPT_DIR, "errors.log")
BLOCK_SEPARATOR  = "\n\n"
RECIPIENTS = ["CHANGE_ME@CHANGE_ME.com"]                               # <===ADMINISTRATOR'S EMAIL. SEE README.md
if SECOND_EMAIL:
    RECIPIENTS.append(SECOND_EMAIL)

# --- Logging ---
def log_msg(message):
    timestamp = datetime.now().isoformat()
    print(f"{timestamp} {message}")
    with open(SUCCESS_LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"{timestamp} {message}\n")

def log_error(message):
    timestamp = datetime.now().isoformat()
    print(f"{timestamp} {message}")
    with open(ERROR_LOG_FILE, "a", encoding="utf-8") as f:
        f.write(f"{timestamp} {message}\n")

def wait_clickable(wait, selector, by=By.XPATH, timeout_msg=None):
    try:
        return wait.until(EC.element_to_be_clickable((by, selector)))
    except TimeoutException:
        log_error(timeout_msg or f"❌ Element not clickable: {selector}")
        raise

# --- Email ---
def send_email(subject, body):
    msg = MIMEText(body)
    msg["Subject"] = subject
    msg["From"] = GMAIL_USER
    msg["To"] = ", ".join(RECIPIENTS)

    try:
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(GMAIL_USER, GMAIL_PASS)
            server.sendmail(GMAIL_USER, RECIPIENTS, msg.as_string())
    except Exception as e:
        log_error(f"❌ Failed to send email: {e}")

def check_and_email_log():
    if not os.path.exists(SUCCESS_LOG_FILE):
        return

    with open(SUCCESS_LOG_FILE, encoding="utf-8") as f:
        lines = f.readlines()

    if any("Clock in with your POS ID" in line for line in lines):
        os.remove(SUCCESS_LOG_FILE)
        print("✅ Found 'Clock in with your POS ID'. Deleted log and exiting.")
        return

    if len(lines) >= 4:
        msg_body = lines[3].strip() + "\n" + lines[4].strip()
    else:
        msg_body = "Log does not contain enough lines."

    nyc_time = datetime.now(pytz.timezone("America/New_York"))
    subject = f"Hotschedules {nyc_time.strftime('%Y-%m-%d %I:%M %p %Z')}"

    send_email(subject, msg_body)
    os.remove(SUCCESS_LOG_FILE)
    print("📧 Email sent and success.log deleted.")

# --- Main flow ---
def main():
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")

    try:
        with webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()), options=options) as driver:
            wait = WebDriverWait(driver, 20)

            # 1. Login
            driver.get("https://app.hotschedules.com/hs/webclock/")
            wait.until(EC.presence_of_element_located((By.ID, "web-clock-username"))).send_keys(USERNAME)
            wait.until(EC.presence_of_element_located((By.XPATH, "(//input[@type='password'])[1]"))).send_keys(PASSWORD)
            wait_clickable(wait, "button.web-clock--button-full-width", By.CSS_SELECTOR).click()
            log_msg("✅ Login succeeded")
            time.sleep(1)

            # 2. Enter POS_ID via keypad
            for digit in POS_ID:
                wait_clickable(wait, f"//div[contains(@class, 'keypad-cell') and normalize-space(text())='{digit}']").click()
                time.sleep(random.uniform(0.12, 0.25))
            log_msg("✅ POS entry simulated")
            time.sleep(1)

            wait_clickable(wait, "button.go-button", By.CSS_SELECTOR).click()
            log_msg("✅ POS entry submitted")

            time.sleep(2)
            page_text = driver.find_element(By.TAG_NAME, "body").text
            log_msg(f"🟢 Final page message:\n{page_text}")

            with open(SUCCESS_LOG_FILE, "a", encoding="utf-8") as f:
                f.write(BLOCK_SEPARATOR)

    except TimeoutException as e:
        log_error(f"⏰ Timeout: {str(e)}")
        with open(ERROR_LOG_FILE, "a", encoding="utf-8") as f:
            traceback.print_exc(file=f)
            f.write(BLOCK_SEPARATOR)
        sys.exit(2)

    except Exception as e:
        log_error(f"❌ Error during automation: {e}")
        with open(ERROR_LOG_FILE, "a", encoding="utf-8") as f:
            traceback.print_exc(file=f)
            f.write(BLOCK_SEPARATOR)
        traceback.print_exc()
        sys.exit(1)

    # ✅ Email after log is written
    check_and_email_log()

if __name__ == "__main__":
    main()
