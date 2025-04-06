#!/bin/bash
# Grey Wolf Hunt Recon Script v1.2
# Author: Onan GreyWolf
# Purpose: Modular, concurrent recon tool for bug bounty hunting
# Inspired by: Jason Haddix's methodology
# Banner
echo -e "\e[1;34m"
echo "🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🐾🔥🔥"
echo "================================================================"
echo "      🐺 GREY WOLF BUG BOUNTY SETUP 🐺"
echo "================================================================"
echo "// 🐺 🌙 The Silent Hunter 🌙 🐺  //"
echo -e "\e[0m"

set -e

show_help() {
    echo "Usage: $0 [options] -d domain.com"
    echo ""
    echo "Options:"
    echo "  -s    Subdomain Enumeration"
    echo "  -l    Live Subdomain Checking"
    echo "  -u    URL Gathering"
    echo "  -j    JavaScript Recon"
    echo "  -c    Content Discovery"
    echo "  -v    Vulnerability Scanning"
    echo "  -d    Target Domain"
    echo "  -all  Run All Stages"
    echo "  -h    Show Help"
}

# Flags
RUN_SUBS=false
RUN_LIVE=false
RUN_URLS=false
RUN_JS=false
RUN_CONTENT=false
RUN_VULNS=false
RUN_ALL=false
DOMAIN=""

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -s) RUN_SUBS=true;;
        -l) RUN_LIVE=true;;
        -u) RUN_URLS=true;;
        -j) RUN_JS=true;;
        -c) RUN_CONTENT=true;;
        -v) RUN_VULNS=true;;
        -all) RUN_ALL=true;;
        -d) DOMAIN="$2"; shift;;
        -h|--help) show_help; exit 0;;
        *) echo "Unknown option: $1"; show_help; exit 1;;
    esac
    shift
done

if [[ -z "$DOMAIN" ]]; then
    echo "Enter target domain:"
    read DOMAIN
fi

# Default if no flags
if ! $RUN_SUBS && ! $RUN_LIVE && ! $RUN_URLS && ! $RUN_JS && ! $RUN_CONTENT && ! $RUN_VULNS && ! $RUN_ALL; then
    RUN_SUBS=true
    RUN_LIVE=true
    RUN_CONTENT=true
fi

OUTDIR="/home/$(whoami)/bug-bounty/$DOMAIN"
mkdir -p "$OUTDIR"
cd "$OUTDIR"

# Subdomain Enumeration
if $RUN_SUBS || $RUN_ALL; then
    echo "[*] Running Subdomain Enumeration"
    (assetfinder --subs-only "$DOMAIN"; subfinder -d "$DOMAIN" -silent; amass enum -passive -d "$DOMAIN") | anew subdomains.txt
fi

# Live Check
if $RUN_LIVE || $RUN_ALL; then
    echo "[*] Checking Live Hosts"
    cat subdomains.txt | naabu -silent -p 80,443 | xargs -P10 -I{} httpx -silent -u {} | anew live-subdomains.txt
fi

# URL Gathering
if $RUN_URLS || $RUN_ALL; then
    echo "[*] Gathering URLs"
    (echo "$DOMAIN" | xargs -P10 -I{} gau {} ; echo "$DOMAIN" | xargs -P10 -I{} katana -u {}) | anew urls.txt
fi

# JavaScript Recon
if $RUN_JS || $RUN_ALL; then
    echo "[*] Extracting JS Endpoints"
    mkdir -p js
    cat live-subdomains.txt | xargs -P10 -I{} bash -c 'curl -s {} | grep -oP "src=\\\".*?\\.js\\\"" | cut -d\" -f2' | anew js/js-urls.txt
    cat js/js-urls.txt | xargs -P10 -I{} python3 /tools/LinkFinder/linkfinder.py -i {} -o cli >> js/js-findings.txt
fi

# Content Discovery
if $RUN_CONTENT || $RUN_ALL; then
    echo "[*] Starting Content Discovery"
    mkdir -p content
    cat live-subdomains.txt | xargs -P10 -I{} ffuf -w /usr/share/wordlists/dirb/common.txt -u {}/FUZZ -of csv -o content/{}/ffuf.csv || true
fi

# Vulnerability Scanning
if $RUN_VULNS || $RUN_ALL; then
    echo "[*] Starting Vulnerability Scanning"
    mkdir -p vulns
    cat live-subdomains.txt | xargs -P10 -I{} bash -c 'nuclei -u {} -o vulns/nuclei.txt; nikto -h {} >> vulns/nikto.txt; wapiti -u {} -o vulns/{} -f html'
fi

echo "[*] Recon complete. Output in $OUTDIR"
