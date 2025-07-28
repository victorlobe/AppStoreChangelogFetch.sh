# 📦 AppStoreChangelogFetch

Simple shell script to fetch the **full changelog** (What’s New) for **every version** ever released of one of your apps on the App Store. Including **release date and time**.

---

## ✅ Features

- Fetches **all versions** of your app using the official App Store Connect API
- Displays:
  - 📦 Version number
  - 📅 Release date (with time)
  - 📝 Full localized changelog (What’s New)
- Includes automatic pagination for large version histories
- Clean output in the terminal
- Configurable:
  - 🌍 Changelog locale (e.g. `en-US`, `de-DE`)
  - 🕓 Date and time format (e.g. `2025-07-28 14:30` or `28.07.2025 14:30`)

---

## 🔧 Requirements

- macOS (required for `date -j` formatting)
- Ruby (preinstalled on macOS)
- [`jq`](https://stedolan.github.io/jq/) (install via `brew install jq`)
- Valid App Store Connect API key

---

## 🛠 Setup

1. Go to [App Store Connect – API Keys](https://appstoreconnect.apple.com/access/integrations/api)
2. Create a new API key
3. Download the `.p8` key file
4. In the script, replace the following placeholders at the top:
   ```bash
   KEY_ID="your_key_id"
   ISSUER_ID="your_issuer_id"
   PRIVATE_KEY_PATH="/path/to/AuthKey.p8"
   APP_ID="your_internal_app_id"

   LOCALE="en-US"                       # or "de-DE", "fr-FR", etc.
   DATE_FORMAT="%Y-%m-%d %H:%M"         # or "%d.%m.%Y %H:%M", etc.
   ```
   - `KEY_ID`: shown next to your API key in App Store Connect
   - `ISSUER_ID`: displayed above the key list
   - `PRIVATE_KEY_PATH`: path to your downloaded `.p8` file
   - `APP_ID`: internal App ID found in the App’s General → App Information section (URL: `apps/{APP_ID}`)
   - `LOCALE`: which localized changelog to show
   - `DATE_FORMAT`: how the date/time should be printed in the terminal

5. Make the script executable:
   ```bash
   chmod +x fetch_appstore_versions.sh
   ```

6. Run the script:
   ```bash
   ./fetch_appstore_versions.sh
   ```

---

## 🧪 Example Output

```text
📦 Version: 6.2
📅 Released: 2025-07-17 18:30
📝 Changelog:
- New map design
- Live tracking improved

📦 Version: 6.1
📅 Released: 2025-06-02 10:00
📝 Changelog:
- Bug fixes and performance improvements
```

---

## 🌍 Localization & Formatting

You can fully control:
- The changelog language via `LOCALE` (e.g. `de-DE`, `en-US`)
- The output date format via `DATE_FORMAT`

📌 Example formats:
| DATE_FORMAT              | Output Example           |
|--------------------------|--------------------------|
| `%Y-%m-%d %H:%M`         | `2025-07-28 14:30`       |
| `%d.%m.%Y %H:%M`         | `28.07.2025 14:30`       |
| `%A, %B %d, %Y %H:%M`    | `Monday, July 28, 2025 14:30` |

---

## 🛡 License

MIT – free to use, modify, and distribute.  
Credits appreciated but not required 😊
