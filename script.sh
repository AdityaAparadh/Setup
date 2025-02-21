#!/bin/bash

#------------------------------------------------------------------------------------+
# Script to configure my packages and keybindings on lab computers with Ubuntu+GNOME |
#------------------------------------------------------------------------------------+

set -e
set -o pipefail
set -u

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

print_step() {
    echo -e "${YELLOW}🔄 $1...${RESET}"
}
print_success() {
    echo -e "${GREEN}✅ $1 completed.${RESET}"
}
print_failure() {
    echo -e "${RED}❌ $1 failed! Exiting.${RESET}" >&2
    exit 1
}

# -------------------------------------------------------------------
# Required Packages
# -------------------------------------------------------------------
print_step "Installing required packages"
sudo apt update && sudo apt install -y neovim git curl unzip gh || print_failure "Package installation"
clear
print_success "Package installation"

# -------------------------------------------------------------------
# keyd Installation and Configuration
# -------------------------------------------------------------------
print_step "Installing keyd"
mkdir -p ~/clone && cd ~/clone || print_failure "Failed to create ~/clone directory"
git clone https://github.com/rvaiya/keyd || print_failure "Failed to clone keyd repository"
cd keyd || print_failure "Failed to enter keyd directory"
make && sudo make install || print_failure "Failed to build and install keyd"
sudo systemctl start keyd || print_failure "Failed to start keyd service"
print_success "keyd installed"
clear
print_step "Configuring keyd"
sudo tee /etc/keyd/default.conf > /dev/null <<EOF || print_failure "Failed to configure keyd"
[ids]
*
[main]
capslock = esc
EOF
sudo keyd reload || print_failure "Failed to reload keyd"
clear
print_success "keyd configured"

# -------------------------------------------------------------------
# Zed Editor Installation
# -------------------------------------------------------------------
print_step "Installing Zed Editor"
curl -fsSL https://zed.dev/install.sh | sh || print_failure "Zed installation"
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc || print_failure "Failed to update PATH"
clear
print_success "Zed Editor installed"
# -------------------------------------------------------------------
# GNOME Keybindings Configuration
# -------------------------------------------------------------------
print_step "Configuring GNOME keybindings"
gsettings set org.gnome.shell.extensions.dash-to-dock hot-keys false || print_failure "Failed to disable GNOME hot-keys"
for i in $(seq 1 9); do
    gsettings set org.gnome.shell.keybindings switch-to-application-${i} '[]' || print_failure "Failed to unset keybinding for application $i"
done

KEYBINDINGS_URL="https://github.com/AdityaAparadh/Setup/releases/download/alpha/keybindings.dconf"
TEMP_FILE="/tmp/keybindings.dconf"

curl -o "$TEMP_FILE" "$KEYBINDINGS_URL" || print_failure "Failed to download GNOME keybindings"
dconf load /org/gnome/desktop/wm/keybindings/ < "$TEMP_FILE" || print_failure "Failed to apply GNOME keybindings"
rm "$TEMP_FILE" || print_failure "Failed to remove temporary file"
clear
print_success "GNOME keybindings configured"
clear
echo -e "${GREEN} All steps completed successfully! System is now set up.${RESET}"
