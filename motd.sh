#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[38;5;39m'
NC='\033[0m' # No Color

get_time_ago() {
    local reboot_time=$1
    local current_time=$(date +%s)
    local diff=$((current_time - reboot_time))
    
    if [ $diff -lt 60 ]; then
        echo "just now"
    elif [ $diff -lt 3600 ]; then
        local minutes=$((diff / 60))
        if [ $minutes -eq 1 ]; then
            echo "1 minute ago"
        else
            echo "$minutes minutes ago"
        fi
    elif [ $diff -lt 86400 ]; then
        local hours=$((diff / 3600))
        if [ $hours -eq 1 ]; then
            echo "1 hour ago"
        else
            echo "$hours hours ago"
        fi
    else
        local days=$((diff / 86400))
        if [ $days -eq 1 ]; then
            echo "1 day ago"
        else
            echo "$days days ago"
        fi
    fi
}

get_network_load() {
    if command -v ifstat >/dev/null 2>&1; then
        local interface="ens3"
        local stats=$(ifstat -i $interface -q 1 1)
        local in_rate=$(echo "$stats" | awk 'NR==3 {print $1}')
        local out_rate=$(echo "$stats" | awk 'NR==3 {print $2}')
        
        local in_load="Low"
        local out_load="Low"
        
        if (( $(echo "$in_rate > 100" | bc -l) )); then
            in_load="Normal"
        fi
        if (( $(echo "$in_rate > 1000" | bc -l) )); then
            in_load="High"
        fi
        
        if (( $(echo "$out_rate > 50" | bc -l) )); then
            out_load="Normal"
        fi
        if (( $(echo "$out_rate > 500" | bc -l) )); then
            out_load="High"
        fi
        
        echo "${in_rate} KB/s in ($in_load), ${out_rate} KB/s out ($out_load)"
    else
        echo "ifstat not installed"
    fi
}

echo

# System information
echo -e "${CYAN}System information as of $(date)${NC}"
(
    echo -e "  ${ORANGE}System load${NC}:\t$(uptime | awk '{print $10,$11,$12,$13,$14}')"
    echo -e "  ${ORANGE}Usage of /${NC}:\t$(df -h / | awk '/\// {print $3" / "$2}')"
    echo -e "  ${ORANGE}Memory usage${NC}:\t$(free -m | awk '/Mem:/ {printf("%.2f%%\n", $3/$2*100)}')"

    # Swap usage with check for division by zero
    swap_total=$(free -m | awk '/Swap:/ {print $2}')
    swap_used=$(free -m | awk '/Swap:/ {print $3}')
    if [ "$swap_total" -gt 0 ]; then
        swap_usage=$(awk "BEGIN {printf \"%.2f%%\n\", $swap_used/$swap_total*100}")
    else
        swap_usage="0.00%"
    fi

    echo -e "  ${ORANGE}Swap usage${NC}:\t$swap_usage"
    echo -e "  ${ORANGE}Processes${NC}:\t$(ps -A | wc -l)"
    echo -e "  ${ORANGE}Users logged in${NC}:\t$(who | wc -l)"
    echo -e "  ${ORANGE}IPv4 address for ens3${NC}:\t$(ip addr show ens3 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
    echo -e "  ${ORANGE}IPv6 address for ens3${NC}:\t$(ip addr show ens3 | grep -oP '(?<=inet6\s)\S+' | head -n 1)"
) | column -t -s $'\t'

echo

# Additional system information
echo -e "${CYAN}Additional System Information${NC}:"
(
    echo -e "  ${ORANGE}Kernel version${NC}:\t$(uname -r)"
    echo -e "  ${ORANGE}Uptime${NC}:\t$(uptime -p)"
    reboot_time=$(who -b | awk '{print $3,$4}')
    reboot_epoch=$(date -d "$reboot_time" +%s)
    echo -e "  ${ORANGE}Last reboot${NC}:\t$(get_time_ago $reboot_epoch)"
    echo -e "  ${ORANGE}CPU usage${NC}:\t$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
    echo -e "  ${ORANGE}Network load${NC}:\t$(get_network_load)"
) | column -t -s $'\t'

echo

# Update information
echo -e "${CYAN}Update information${NC}:"
updates=$(apt list --upgradable 2>/dev/null)
security_updates=$(echo "$updates" | grep -c security)
other_updates=$(($(echo "$updates" | wc -l) - security_updates - 1))
(
    echo -e "  ${ORANGE}Security updates${NC}:\t$security_updates"
    echo -e "  ${ORANGE}General updates${NC}:\t$other_updates"
) | column -t -s $'\t'

echo

# Disk usage
echo -e "${CYAN}Disk Usage${NC}:"
(
    echo -e "  ${ORANGE}Root (/)${NC}:\t$(df -h / | awk '/\// {print $3" / "$2}')"
    echo -e "  ${ORANGE}Home (/home)${NC}:\t$(df -h /home | awk '/\// {print $3" / "$2}')"
    echo -e "  ${ORANGE}Docker (/var/lib/docker)${NC}:\t$(df -h /var/lib/docker | awk 'NR==2 {print $3" / "$2}')"
) | column -t -s $'\t'

echo

# Docker container information
echo -e "${CYAN}Docker Containers${NC}:"
if command -v docker >/dev/null 2>&1; then
  (
    echo -e "  NAMES\tSTATUS\tCONTAINER ID"
    docker ps --format "{{.Names}}\t{{.Status}}\t{{.ID}}" | \
    while IFS=$'\t' read -r name status id; do
      printf "  ${ORANGE}%s${NC}\t%s\t%s\n" "$name" "$status" "$id"
    done
  ) | column -t -s $'\t'
else
  echo "Docker is not installed or not accessible."
fi

echo

echo -e "${ORANGE}════════════════════════════════════════════${NC}"