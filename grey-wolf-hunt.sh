#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Grey Wolf Recon Script v1.0
# Author: Onan GreyWolf
# Purpose: Modular, concurrent recon tool for bug bounty hunting
# Inspired by: Jason Haddix's methodology
# ───────────────────────────────────────────────────────────────

set -euo pipefail

# ──────────────── CONFIGURATION ─────────────────
threads=10
xargs_cmd="xargs -P $threads -I {}"

# ──────────────── FLAGS ─────────────────
target=""
run_subdomains=false
run_live=false
run_urls=false
run_js=false
run_content=false
run_vulns=false

while getopts ":sluijcvhall" opt; do
  case $opt in
    s) run_subdomains=true;;
    l) run_live=true;;
    u) run_urls=true;;
    j) run_js=true;;
    c) run_content=true;;
    v) run_vulns=true;;
    h)
      echo "Usage: $0 [-s] [-l] [-u] [-j] [-c] [-v] domain.com"
      exit 0;;
    a) run_subdomains=true; run_live=true; run_content=true;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1;;
  esac
done

shift $((OPTIND -1))
target=$1
if [[ -z "${target:-}" ]]; then
  read -rp "Enter target domain: " target
fi

outdir="/output/$target"
mkdir -p "$outdir"
cd "$outdir" || exit 1

# ──────────────── SUBDOMAIN ENUMERATION ─────────────────
if $run_subdomains; then
  echo "[+] Enumerating subdomains for $target..."
  (assetfinder --subs-only "$target"; \
   subfinder -d "$target" -silent; \
   amass enum -passive -d "$target") | anew subdomains.txt
fi

# ──────────────── LIVE SUBDOMAINS ─────────────────
if $run_live; then
  echo "[+] Checking live hosts..."
  naabu -host "$target" -silent | anew naabu.txt
  cat subdomains.txt | $xargs_cmd httpx -silent -status-code -title -tech-detect -no-color | anew live-subdomains.txt
fi

# ──────────────── URL GATHERING ─────────────────
if $run_urls; then
  echo "[+] Gathering URLs..."
  (gau "$target"; katana -u "$target" -silent; hakrawler -url "$target") | anew urls.txt
fi

# ──────────────── JS RECON ─────────────────
if $run_js; then
  echo "[+] Scanning JS files..."
  grep ".js" urls.txt | sort -u | $xargs_cmd python3 /opt/LinkFinder/linkfinder.py -i {} -o cli >> js-findings.txt
fi

# ──────────────── CONTENT DISCOVERY ─────────────────
if $run_content; then
  echo "[+] Running content discovery..."
  ffuf -w /usr/share/seclists/Discovery/Web-Content/common.txt -u https://$target/FUZZ -of csv -o content.csv
fi

# ──────────────── VULNERABILITY SCANNING ─────────────────
if $run_vulns; then
  echo "[+] Running vulnerability scans..."
  nuclei -l live-subdomains.txt -o nuclei.txt
  nikto -host "$target" -output nikto.txt
  wapiti -u "https://$target" -f txt -o wapiti.txt
fi

# ──────────────── DONE ─────────────────
echo "[+] Recon complete. Output saved in $outdir"
