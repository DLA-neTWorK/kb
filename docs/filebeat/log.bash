#!/bin/bash

# Define colors for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default values for variables
ES_HOST=":9200"
ES_USER="elastic"
ES_PASS=""
ES_INDEX="syslog-*"
ES_QUERY_ENDPOINT="http://$ES_HOST/$ES_INDEX/_search"
UFW_LOG_LEVEL="low"
MAX_RETRIES=12
SLEEP_DURATION=5
TEST_MESSAGE="dla.network script test"

# File Paths
ES_GPG_KEY_PATH="/etc/apt/trusted.gpg.d/elastic-archive-keyring.gpg"
ES_APT_LIST_FILE="/etc/apt/sources.list.d/elastic-8.x.list"
RSYSLOG_CONF="/etc/rsyslog.d/logstash.conf"
ZABBIX_GPG_FILE="zabbix-release_latest+ubuntu24.04_all.deb"

# Function to create a bulletin board style message
bulletin_board() {
  local message="$1"
  local border_length=$(( ${#message} + 4 ))
  local border=$(printf '%*s' "$border_length" | tr ' ' '=')
  echo -e "${BLUE}$border${NC}"
  echo -e "${YELLOW}| $message |${NC}"
  echo -e "${BLUE}$border${NC}"
}

# Function to display help
show_help() {
  bulletin_board "Help Menu"
  echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
  echo -e "  --ES_host       Set the Elasticsearch host (default: :9200)"
  echo -e "  --ES_user       Set the Elasticsearch username (default: elastic)"
  echo -e "  --ES_pass       Set the Elasticsearch password (default: empty)"
  echo -e "  --ES_index      Set the Elasticsearch index name (default: syslog-*)"
  echo -e "  --UFW_log_level Set the UFW logging level (default: low)"
  echo -e "  --help          Display this help message"
  exit 0
}

# Check for prerequisites
check_prerequisites() {
  bulletin_board "Checking for Required Software"
  dependencies=("curl" "lsb_release" "timedatectl" "systemctl" "gpg" "apt-get" "wget" "dpkg")
  for dependency in "${dependencies[@]}"; do
    if ! command -v $dependency &> /dev/null; then
      echo -e "${RED}Error: $dependency is not installed. Please install it and rerun the script.${NC}"
      exit 1
    fi
  done
  echo -e "${GREEN}All prerequisites are installed.${NC}"
}

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --ES_host) ES_HOST="$2"; shift ;;
    --ES_user) ES_USER="$2"; shift ;;
    --ES_pass) ES_PASS="$2"; shift ;;
    --ES_index) ES_INDEX="$2"; ES_QUERY_ENDPOINT="http://$ES_HOST/$ES_INDEX/_search"; shift ;;
    --UFW_log_level) UFW_LOG_LEVEL="$2"; shift ;;
    --help) show_help ;;
    *) echo -e "${RED}Unknown parameter passed: $1${NC}"; show_help; exit 1 ;;
  esac
  shift
done

# Check for prerequisites
check_prerequisites

# Check if the operating system is Ubuntu
bulletin_board "Operating System Check"
OS=$(lsb_release -si)
if [[ "$OS" != "Ubuntu" ]]; then
  echo -e "${RED}This script is designed to run only on Ubuntu. Detected OS: $OS. Exiting...${NC}"
  exit 1
fi
echo -e "${GREEN}Ubuntu detected. Proceeding...${NC}"

# Masked password for display
MASKED_ES_PASS=$(echo "$ES_PASS" | sed 's/./*/g')

# Display settings
bulletin_board "Configuration Settings"
echo -e "${YELLOW}Elasticsearch Host: ${NC}$ES_HOST"
echo -e "${YELLOW}Elasticsearch User: ${NC}$ES_USER"
echo -e "${YELLOW}Elasticsearch Password: ${NC}${MASKED_ES_PASS}"
echo -e "${YELLOW}UFW Log Level: ${NC}$UFW_LOG_LEVEL"

# Function to set the timezone
set_timezone() {
  bulletin_board "Timezone Configuration"
  TIMEZONES=("America/New_York" "America/Chicago" "America/Denver" "America/Los_Angeles")
  for i in "${!TIMEZONES[@]}"; do
    echo -e "${BLUE}$((i+1))) ${TIMEZONES[$i]}${NC}"
  done
  read -p "Enter the number corresponding to your timezone (1-${#TIMEZONES[@]}): " timezone_choice
  sudo timedatectl set-timezone "${TIMEZONES[$((timezone_choice-1))]:-America/Chicago}"
  echo -e "${GREEN}Timezone set to ${TIMEZONES[$((timezone_choice-1))]:-America/Chicago}.${NC}"
}

# Set the timezone
set_timezone

# Function to configure Zabbix repository
configure_zabbix_repo() {
  read -p "Do you want to configure the Zabbix repository? (y/n): " zabbix_install
  if [[ "$zabbix_install" == "y" || "$zabbix_install" == "Y" ]]; then
    bulletin_board "Configuring Zabbix Repository"
    ZABBIX_VERSIONS=("6.4" "7.0" "7.2")
    for i in "${!ZABBIX_VERSIONS[@]}"; do
      echo -e "${BLUE}$((i+1))) Zabbix ${ZABBIX_VERSIONS[$i]}${NC}"
    done
    read -p "Enter the number corresponding to the Zabbix version (1-${#ZABBIX_VERSIONS[@]}): " zabbix_choice
    ZABBIX_VERSION="${ZABBIX_VERSIONS[$((zabbix_choice-1))]}"
    ZABBIX_URL="https://repo.zabbix.com/zabbix/$ZABBIX_VERSION/ubuntu/pool/main/z/zabbix-release/$ZABBIX_GPG_FILE"
    echo -e "${YELLOW}Downloading Zabbix version $ZABBIX_VERSION...${NC}"
    wget $ZABBIX_URL -O $ZABBIX_GPG_FILE
    sudo dpkg -i $ZABBIX_GPG_FILE && sudo apt-get update
    echo -e "${GREEN}Zabbix repository for version $ZABBIX_VERSION configured successfully.${NC}"
  else
    echo -e "${YELLOW}Skipping Zabbix repository configuration.${NC}"
  fi
}

# Configure Zabbix repository
configure_zabbix_repo

# Function to configure Webmin repository and installation
configure_webmin() {
  read -p "Do you want to configure and install Webmin? (y/n): " webmin_install
  if [[ "$webmin_install" == "y" || "$webmin_install" == "Y" ]]; then
    bulletin_board "Configuring Webmin"
    # Added a timeout to the curl command and error handling
    curl -o webmin-setup-repos.sh https://raw.githubusercontent.com/webmin/webmin/master/webmin-setup-repos.sh --max-time 30
    if [[ $? -ne 0 ]]; then
      echo -e "${RED}Error: Failed to download the Webmin setup script. Please check your network connection.${NC}"
      exit 1
    fi
    sudo sh webmin-setup-repos.sh
    sudo apt-get update
    sudo apt-get install -y webmin --install-recommends
    echo -e "${GREEN}Webmin installed successfully.${NC}"

    # Add Webmin port to UFW if UFW is running
    if systemctl is-active --quiet ufw; then
      echo -e "${YELLOW}Adding Webmin port 10000 to UFW...${NC}"
      sudo ufw allow 10000/tcp
      echo -e "${GREEN}Webmin port 10000 added to UFW.${NC}"
    else
      echo -e "${YELLOW}UFW is not running or not installed. Skipping UFW configuration for Webmin.${NC}"
    fi
  else
    echo -e "${YELLOW}Skipping Webmin installation.${NC}"
  fi
}

# Configure Webmin
configure_webmin

# Elasticsearch setup
bulletin_board "Setting Up Elasticsearch"
if [ ! -f "$ES_GPG_KEY_PATH" ]; then
  echo -e "${YELLOW}Adding Elasticsearch GPG key...${NC}"
  curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o $ES_GPG_KEY_PATH
fi
if ! grep -q "https://artifacts.elastic.co/packages/8.x/apt" $ES_APT_LIST_FILE; then
  echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee -a $ES_APT_LIST_FILE
fi
sudo apt-get update

# Install Filebeat
sudo apt-get install -y apt-transport-https filebeat

# Configure Filebeat
bulletin_board "Configuring Filebeat"
sudo tee /etc/filebeat/filebeat.yml << EOF
filebeat.inputs:
- type: filestream
  id: my-filestream-id
  enabled: true
  paths:
    - /var/log/*.log

filebeat.config.modules:
  path: \${path.config}/modules.d/*.yml
  reload.enabled: false

setup.template.settings:
  index.number_of_shards: 1

output.elasticsearch:
  hosts: ["$ES_HOST"]
  username: "$ES_USER"
  password: "$ES_PASS"

processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~
EOF

# Enable and start Filebeat
sudo systemctl enable filebeat && sudo systemctl restart filebeat

# Configure Rsyslog
bulletin_board "Configuring Rsyslog"
if [ ! -f "$RSYSLOG_CONF" ]; then
  sudo tee $RSYSLOG_CONF << EOF
*.* action(type="omfwd" target="" port="5518" protocol="tcp")
EOF
fi
sudo systemctl restart rsyslog

# Configure UFW
bulletin_board "Configuring UFW"
if systemctl is-active --quiet ufw; then
  sudo ufw logging $UFW_LOG_LEVEL
  sudo ufw status verbose
else
  echo -e "${RED}UFW is not installed or running.${NC}"
fi

# Test Elasticsearch
bulletin_board "Testing Elasticsearch"
logger "$TEST_MESSAGE"
sleep 15
response=$(curl -s -u "$ES_USER:$ES_PASS" -X GET "$ES_QUERY_ENDPOINT" -H 'Content-Type: application/json' -d'
{
  "query": {
    "bool": {
      "must": [
        { "match": { "message": "'"$TEST_MESSAGE"'" } },
        { "range": { "@timestamp": { "gte": "now-1m" } } }
      ]
    }
  }
}')

# Display the full, verbose Elasticsearch response
echo -e "${YELLOW}Full Elasticsearch Response:${NC}"
echo -e "${BLUE}${response//"$ES_PASS"/"*****"}${NC}"

# Check if the response contains the test message
if [[ $response == *'"hits":{"total":{"value":0'* ]]; then
  echo -e "${RED}Error: Test message not found in Elasticsearch. Please check your configuration.${NC}"
else
  echo -e "${GREEN}Test message successfully found in Elasticsearch!${NC}"
fi

bulletin_board "Script Execution Complete"
echo -e "${GREEN}All tasks completed successfully!${NC}"

