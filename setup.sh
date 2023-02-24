#!/bin/bash
## Automated Bug Bounty recon script dependency installer
## By Cas van Cooten

if [ "$EUID" -ne 0 ]
then
  echo "[-] Installation requires elevated privileges, please run as root"
  echo "[*] Running 'sudo $0' will install for current user"
  echo "[*] Running 'sudo su; $0' will install for root user"
  exit 1
fi

if [[ "$OSTYPE" != "linux-gnu" ]] || [[ "$(uname -m)" != "x86_64" ]]
then
  echo "[-] Installation requires 64-bit Linux"
  exit 1
fi

for arg in "$@"
do
    case $arg in
        -h|--help)
        echo "BugBountyHunter Dependency Installer"
        echo " "
        echo "$0 [options]"
        echo " "
        echo "options:"
        echo "-h, --help                show brief help"
        echo "-t, --toolsdir            tools directory, defaults to '/opt'"
        echo ""
        echo "Note: If you choose a non-default tools directory, please adapt the default in the BugBountyAutomator.sh file or pass the -t flag to ensure it finds the right tools."
        echo ""
        echo "example:"
        echo "$0 -t /opt"
        exit 0
        ;;
        -t|--toolsdir)
        toolsDir="$2"
        shift
        shift
        ;;
    esac
done

if [ -z "$toolsDir" ]
then
    toolsDir="/opt"
fi

echo "[*] INSTALLING DEPENDENCIES IN \"$toolsDir\"..."
echo "[!] NOTE: INSTALLATION HAS BEEN TESTED ON UBUNTU ONLY. RESULTS MAY VARY FOR OTHER DISTRIBUTIONS."

baseDir=$PWD
username="$(logname 2>/dev/null || echo root)"
homeDir=$(eval echo "~$username")

mkdir -p "$toolsDir"
cd "$toolsDir" || { echo "Something went wrong"; exit 1; }

# Various apt packages
echo "[*] Running apt update and installing apt-based packages, this may take a while..."
apt-get update >/dev/null
apt-get install -y xvfb dnsutils nmap python3.5 python2 python3-pip curl wget unzip git libfreetype6 libfontconfig1 >/dev/null
rm -rf /var/lib/apt/lists/*

# Golang
go version &> /dev/null
if [ $? -ne 0 ]; then
    echo "[*] Installing Golang..."
    wget -q https://golang.org/dl/go1.19.4.linux-amd64.tar.gz
    tar -xvf go1.19.4.linux-amd64.tar.gz -C /usr/local >/dev/null
    rm -rf ./go1.19.4.linux-amd64.tar.gz >/dev/null
    export GOROOT="/usr/local/go"
    export GOPATH="$homeDir/.go"
    export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin:${PATH}"
else
    echo "[*] Skipping Golang install, already installed."
    echo "[!] Note: This may cause errors. If it does, check your Golang version and settings."
fi

# Go packages
echo "[*] Installing various Go packages..."
export GO111MODULE="on"
go install github.com/lc/gau@latest &>/dev/null
go install github.com/tomnomnom/gf@latest &>/dev/null
go install github.com/jaeles-project/gospider@latest &>/dev/null
go install github.com/tomnomnom/qsreplace@latest &>/dev/null
go install github.com/haccer/subjack@latest &>/dev/null
go install github.com/OJ/gobuster@latest &>/dev/null
go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest &>/dev/null
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest &>/dev/null

# Nuclei-templates
nuclei -update-templates -update-template-dir $toolsDir/nuclei-templates &>/dev/null

# PhantomJS (removed from  Kali packages)
echo "[*] Installing PhantomJS..."
wget -q https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
tar xvf phantomjs-2.1.1-linux-x86_64.tar.bz2 >/dev/null
rm phantomjs-2.1.1-linux-x86_64.tar.bz2
cp $toolsDir/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin/phantomjs

# Webscreenshot
echo "[*] Installing WebScreenshot via pip..."
pip3 install webscreenshot >/dev/null

#install assetfinder
echo "[*] Installing assetfinder..."
go install github.com/tomnomnom/assetfinder@latest &>/dev/null

#install httprobe
go install github.com/tomnomnom/httprobe@latest &>/dev/null

go install github.com/tomnomnom/gf@latest &>/dev/null

#install fff
go install github.com/tomnomnom/fff@latest &>/dev/null

# Subjack fingerprints file
echo "[*] Installing Subjack fingerprints..."
mkdir "$toolsDir/subjack"
wget -q https://raw.githubusercontent.com/haccer/subjack/master/fingerprints.json -O $toolsDir/subjack/fingerprints.json

# GoBuster temporary files wordlist
echo "[*] Installing GoBuster wordlist..."
mkdir "$toolsDir/wordlists"
wget -q https://raw.githubusercontent.com/Bo0oM/fuzz.txt/master/fuzz.txt -O $toolsDir/wordlists/tempfiles.txt

# HTTPX
echo "[*] Installing HTTPX..."
wget -q https://github.com/projectdiscovery/httpx/releases/download/v1.2.5/httpx_1.2.5_linux_amd64.zip
unzip -j httpx_1.2.5_linux_amd64.zip -d /usr/bin/ httpx >/dev/null
rm httpx_1.2.5_linux_amd64.zip

# Amass
echo "[*] Installing Amass..."
wget -q https://github.com/OWASP/Amass/releases/download/v3.21.2/amass_linux_amd64.zip
unzip -q amass_linux_amd64.zip
mv amass_linux_amd64 amass
rm amass_linux_amd64.zip
cp $toolsDir/amass/amass /usr/bin/amass

# Gf-patterns
echo "[*] Installing Gf-patterns..."
git clone -q https://github.com/1ndianl33t/Gf-Patterns
mkdir "$homeDir"/.gf
cp "$toolsDir"/Gf-Patterns/*.json "$homeDir"/.gf


#installing ffuf
go install github.com/ffuf/ffuf/v2@latest &>/dev/null


# nrich
echo "[*] Installing nrich..."
wget -q https://gitlab.com/api/v4/projects/33695681/packages/generic/nrich/latest/nrich_latest_amd64.deb
dpkg -i nrich_latest_amd64.deb &>/dev/null
rm nrich_latest_amd64.deb

#save file from https://github.com/danielmiessler/SecLists/raw/master/Discovery/Web-Content/raft-large-files.txt
echo "[*] Saving raft-large-files.txt..."
wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/raft-large-files.txt -O $toolsDir/wordlists/raft-large-files.txt

#save file from https://github.com/danielmiessler/SecLists/raw/master/Discovery/Web-Content/directory-list-lowercase-2.3-small.txt
echo "[*] Saving directory-list-lowercase-2.3-small.txt..."
wget -q https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-lowercase-2.3-small.txt -O $toolsDir/wordlists/directory-list-lowercase-2.3-small.txt

# Persist configured environment variables via global profile.d script
echo "[*] Setting environment variables..."
if [ -f "$homeDir"/.bashrc ]
then
    { echo "export GOROOT=/usr/local/go";
    echo "export GOPATH=$homeDir/go";
    echo 'export PATH=$PATH:$GOPATH/bin:$GOROOT/bin';
    echo "export GO111MODULE=on"; } >> "$homeDir"/.bashrc
fi

#setup subfinder
echo "[*] Setting up subfinder..."
#get the Shodan API key from user
$shodan = read-host "Enter your Shodan API key"
$virustotal = read-host "Enter your VirusTotal API key"
$securitytrails = read-host "Enter your SecurityTrails API key"
$binaryEdge = read-host "Enter your BinaryEdge API key"
#add api keys to $HOME/.config/subfinder/config.yaml in the format: binaryedge: - key
echo "binaryedge: \n - $binaryEdge" > $homeDir/.config/subfinder/config.yaml
echo "virustotal: \n - $virustotal" >> $homeDir/.config/subfinder/config.yaml
echo "securitytrails: \n - $securitytrails" >> $homeDir/.config/subfinder/config.yaml
echo "shodan: \n - $shodan" >> $homeDir/.config/subfinder/config.yaml


if [ -f "$homeDir"/.zshrc ]
then
    { echo "export GOROOT=/usr/local/go";
    echo "export GOPATH=$homeDir/go";
    echo 'export PATH=$PATH:$GOPATH/bin:$GOROOT/bin';
    echo "export GO111MODULE=on"; } >> "$homeDir"/.zshrc
fi

# Cleanup
apt remove unzip -y &>/dev/null
cd "$baseDir" || { echo "Something went wrong"; exit 1; }

echo "[*] SETUP FINISHED."
exit 0
