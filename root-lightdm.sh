#!/bin/bash

set -e

# Functions for logging
log() { echo "[INFO] $1"; }
error() { echo "[ERROR] $1" >&2; exit 1; }

# Parameters with defaults
USER="${1:-$(logname)}"
HOME_DIR="/home/$USER"

# Check root
if [ "$EUID" -ne 0 ]; then
    error "Please run as root."
fi

# Check if bspwm is installed
if ! command -v bspwm &> /dev/null; then
    log "bspwm not found. Installing..."
    apt-get update
    apt-get -y install bspwm || error "Failed to install bspwm."
else
    log "bspwm is already installed."
fi

# Install LightDM if not present
if ! dpkg -l | grep -qw lightdm; then
    log "Installing LightDM..."
    apt-get -y install lightdm lightdm-gtk-greeter || error "Failed to install LightDM."
else
    log "LightDM is already installed."
fi

# Create bspwm session launcher
BSPWM_SESSION="/usr/bin/bspwm-session"
if [ ! -f "$BSPWM_SESSION" ]; then
    log "Creating bspwm session launcher..."
    echo -e "#!/bin/bash\nexec bspwm" > "$BSPWM_SESSION"
    chmod +x "$BSPWM_SESSION"
fi

# Register bspwm session
BSPWM_DESKTOP="/usr/share/xsessions/bspwm.desktop"
if [ ! -f "$BSPWM_DESKTOP" ]; then
    log "Registering bspwm session..."
    cat > "$BSPWM_DESKTOP" << EOF
[Desktop Entry]
Name=BSPWM
Comment=BSP window manager session
Exec=/usr/bin/bspwm-session
Type=Application
EOF
fi

# Configure LightDM
LIGHTDM_CONF_DIR="/etc/lightdm/lightdm.conf.d"
mkdir -p "$LIGHTDM_CONF_DIR"
CONFIG_FILE="$LIGHTDM_CONF_DIR/50-bspwm.conf"

# 
cat > "$CONFIG_FILE" << EOF
[Seat:*]
user-session=bspwm
greeter-hide-users=false
greeter-allow-guest=true
autologin-guest=true
allow-user-switching=true
EOF

# Change ownership to user
chown "$USER:$USER" "$BSPWM_SESSION" "$BSPWM_DESKTOP" "$CONFIG_FILE"

# Restart LightDM
read -p "All set. Do you want to restart LightDM now? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    log "Restarting LightDM..."
    systemctl restart lightdm
else
    log "You can restart LightDM later with: systemctl restart lightdm"
fi
