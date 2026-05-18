"""
Selenium smoke test for the Expense app running on Flutter web.

What this does:
  1. Boots a Chrome browser pointed at http://localhost:8080
  2. Walks the major screens (onboarding -> register -> dashboard -> groups -> create group
     -> group detail -> add expense -> balances -> profile -> theme toggle)
  3. Captures a screenshot at each step into  tests/screenshots/<step>.png
  4. Records any console errors / unhandled exceptions from the page

Selenium can't see Flutter widget semantics directly (Flutter renders to canvas),
so we drive the UI by clicking pixel coordinates relative to the viewport.
That's brittle if the layout shifts, but works for capturing screenshots.

Run:
    python tests/selenium_smoke.py
"""

from __future__ import annotations

import os
import sys
sys.stdout.reconfigure(encoding="utf-8")
import time
import json
import random
import string
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait

APP_URL = os.environ.get("APP_URL", "http://localhost:8080")
ROOT = Path(__file__).resolve().parent
SHOTS = ROOT / "screenshots"
SHOTS.mkdir(parents=True, exist_ok=True)

# A unique user per run so repeats don't trip "email taken"
suffix = "".join(random.choices(string.ascii_lowercase + string.digits, k=6))
TEST_NAME = f"Selenium Tester {suffix}"
TEST_EMAIL = f"selenium+{suffix}@demo.io"
TEST_PASSWORD = "Password123!"


def shot(driver, name):
    p = SHOTS / f"{name}.png"
    driver.save_screenshot(str(p))
    print(f"  📸  {p.name}")


def click_at(driver, x, y):
    """Click at a fractional viewport position (0..1).

    Selenium 4 uses the W3C actions API, which measures offsets from the
    element's center. We convert (x, y) into a center-relative offset.
    """
    w = driver.execute_script("return window.innerWidth")
    h = driver.execute_script("return window.innerHeight")
    cx, cy = w / 2, h / 2
    dx = int(w * x - cx)
    dy = int(h * y - cy)
    body = driver.find_element(By.TAG_NAME, "body")
    ActionChains(driver).move_to_element_with_offset(body, dx, dy).click().perform()
    time.sleep(0.4)


def type_text(driver, text):
    actions = ActionChains(driver)
    for ch in text:
        actions.send_keys(ch)
    actions.perform()
    time.sleep(0.2)


def get_console_errors(driver):
    """Return any SEVERE-level console messages logged by the page."""
    try:
        logs = driver.get_log("browser")
    except Exception:
        return []
    return [e for e in logs if e.get("level") == "SEVERE"]


def main():
    print(f"→ Launching Chrome targeting {APP_URL}")
    opts = Options()
    opts.add_argument("--window-size=1280,860")
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--disable-gpu")
    # Isolate from the user's regular Chrome profile so we don't conflict.
    profile_dir = Path(os.environ.get("TEMP", "C:/temp")) / f"selenium-chrome-{os.getpid()}"
    opts.add_argument(f"--user-data-dir={profile_dir}")
    opts.set_capability("goog:loggingPrefs", {"browser": "ALL"})

    driver = webdriver.Chrome(options=opts)
    failures = []

    try:
        driver.get(APP_URL)

        # Flutter web is slow to first paint — wait for splash + onboarding
        print("→ Waiting for first frame…")
        time.sleep(8)
        shot(driver, "01_onboarding")

        # The boot loader should be gone now. If it isn't, that's a bug.
        loader = driver.execute_script("return !!document.getElementById('loading');")
        if loader:
            failures.append("Boot loader (#loading) is still in DOM after first frame")

        # ── Onboarding ────────────────────────────────────────────────────────────────
        # The "Next" button sits at the bottom of the screen. Click ~85% down.
        for i in range(2):
            click_at(driver, 0.5, 0.86)
            time.sleep(0.6)
        shot(driver, "02_onboarding_last")
        # "Get started" button -> register
        click_at(driver, 0.5, 0.86)
        time.sleep(1.5)
        shot(driver, "03_register_empty")

        # ── Register ──────────────────────────────────────────────────────────────────
        # Name field is the first focusable field. Tab through and type.
        ActionChains(driver).send_keys(Keys.TAB).perform()  # focus name
        time.sleep(0.2)
        ActionChains(driver).send_keys(TEST_NAME).perform()
        ActionChains(driver).send_keys(Keys.TAB).send_keys(TEST_EMAIL).perform()
        ActionChains(driver).send_keys(Keys.TAB).send_keys(TEST_PASSWORD).perform()
        time.sleep(0.5)
        shot(driver, "04_register_filled")

        # Click "Create account" button at the bottom
        click_at(driver, 0.5, 0.78)
        time.sleep(3)
        shot(driver, "05_dashboard_after_register")

        # ── Dashboard ─────────────────────────────────────────────────────────────────
        # Switch theme via Profile tab
        click_at(driver, 0.92, 0.96)  # rightmost nav item (profile)
        time.sleep(1.5)
        shot(driver, "06_profile_light")

        # The "Theme" dropdown is roughly in the upper part of preferences. Click it.
        # (Brittle — but captures the visual.)
        click_at(driver, 0.85, 0.40)
        time.sleep(0.6)
        shot(driver, "07_theme_dropdown_open")
        # Click "Dark" option (about 2 lines below)
        click_at(driver, 0.85, 0.47)
        time.sleep(1)
        shot(driver, "08_profile_dark")

        # Reload page in dark mode — earlier bug was a white loader covering content.
        driver.refresh()
        time.sleep(6)
        shot(driver, "09_dark_after_refresh")

        loader_still = driver.execute_script("return !!document.getElementById('loading');")
        if loader_still:
            failures.append("Loader still present after refresh in dark mode")

        # ── Groups tab ────────────────────────────────────────────────────────────────
        click_at(driver, 0.36, 0.96)  # 2nd nav item
        time.sleep(1.2)
        shot(driver, "10_groups_list")

        # Tap "New group" tile (top-left action tile)
        click_at(driver, 0.27, 0.30)
        time.sleep(1.2)
        shot(driver, "11_create_group_screen")

        ActionChains(driver).send_keys(Keys.TAB).perform()
        ActionChains(driver).send_keys(f"Selenium Trip {suffix}").perform()
        time.sleep(0.4)
        shot(driver, "12_create_group_filled")

        # Click "Create group" button at the bottom
        click_at(driver, 0.5, 0.93)
        time.sleep(2.5)
        shot(driver, "13_group_detail")

        # ── Activity tab ─────────────────────────────────────────────────────────────
        click_at(driver, 0.64, 0.96)
        time.sleep(1.2)
        shot(driver, "14_activity")

        # ── Profile again, sign out ──────────────────────────────────────────────────
        click_at(driver, 0.92, 0.96)
        time.sleep(1)
        shot(driver, "15_profile_final")

        # ── Console errors ───────────────────────────────────────────────────────────
        errors = get_console_errors(driver)
        if errors:
            (SHOTS / "console_errors.json").write_text(
                json.dumps(errors, indent=2), encoding="utf-8"
            )
            print(f"  ⚠️  {len(errors)} SEVERE console messages — saved to console_errors.json")

        print()
        if failures:
            print("FAILURES:")
            for f in failures:
                print(f"  ❌ {f}")
            sys.exit(1)
        else:
            print(f"✅ Smoke test passed — {len(list(SHOTS.glob('*.png')))} screenshots in {SHOTS}")

    finally:
        driver.quit()


if __name__ == "__main__":
    main()
