# Dockerfile for Grey Wolf Recon
FROM kalilinux/kali-rolling

LABEL maintainer="OnanT <onan.thomas.08@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools
RUN apt-get update && \
    apt-get install -y git curl wget python3 python3-pip golang make unzip parallel xargs && \
    apt-get install -y assetfinder subfinder amass naabu httpx gau ffuf nuclei nikto wapiti jq && \
    apt-get clean

# Install Katana
RUN go install github.com/projectdiscovery/katana/cmd/katana@latest && \
    mv /root/go/bin/katana /usr/local/bin/

# Install anew
RUN go install github.com/tomnomnom/anew@latest && \
    mv /root/go/bin/anew /usr/local/bin/

# Install LinkFinder
RUN git clone https://github.com/GerbenJavado/LinkFinder.git /tools/LinkFinder && \
    pip3 install -r /tools/LinkFinder/requirements.txt

# Set working directory
WORKDIR /recon

COPY grey-wolf-hunt.sh /usr/local/bin/grey-wolf-hunt.sh
RUN chmod +x /usr/local/bin/grey-wolf-hunt.sh

ENTRYPOINT ["grey-wolf-hunt.sh"]
