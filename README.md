# VPS Setup

1. After logging in, update and upgrage pkgs
   - `sudo apt update && sudo apt upgrade -y`

2. download the script directly to your VPS using wget.
- `wget https://raw.githubusercontent.com/Boiln/vR-VPS/main/setup_vps.sh`

3. Make the script executable:
- `chmod +x setup_vps.sh`

4. Run the script:
- `sudo ./setup_vps.sh`

# Minimal Useful motd
- `motd.sh` is located `/etc/profile.d/motd.sh`.
  
![motd](https://i.imgur.com/Qj1xys3.png)
