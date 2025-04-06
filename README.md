#Dr.Cokes-G
#Banner
# "🔥🔥🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🔥🔥"
# "=================================================="
# "      🐺 GREY WOLF BUG BOUNTY SETUP🐺"
# "=================================================="
# "// 🐺 🌙 Silent Hunter 🐺 🌙 //"

# 🐺 Grey Wolf Hunt

> A modular, concurrent recon script inspired by Jason Haddix’s bug bounty methodology. Optimized with `xargs -P`, filtering, and Docker-ready execution.

## 📌 Features

- **Modular Stages** – Selectively run parts of the workflow
- **Subdomain Enumeration** – `assetfinder`, `subfinder`, `amass`
- **Live Subdomain Probing** – `naabu`, `httpx`
- **URL Gathering** – `gau`, `katana`
- **JavaScript Recon** – `LinkFinder`
- **Content Discovery** – `ffuf`
- **Vulnerability Scanning** – `nuclei`, `nikto`, `wapiti`
- **Concurrency Support** – `xargs -P10` for parallel execution
- **Output Filtering** – `anew` to avoid duplicates
- **Dockerized** – Use without worrying about local dependencies

---

## ⚙️ Usage

```bash
./grey-wolf-hunt.sh [options] -d target.com


Options
Flag	Description
-s	Run Subdomain Enumeration
-l	Live Check for Subdomains
-u	URL Gathering
-j	JavaScript Recon
-c	Content Discovery
-v	Vulnerability Scanning
-all	Run all stages
-h	Show help
If no flags are passed, the script defaults to -s -l -c.
