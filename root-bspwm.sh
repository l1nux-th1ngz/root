#!/bin/bash

set -e

# Usage: ./root-bspwm.sh username
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 username"
  exit 1
fi

TARGET_USER="$1"
HOME_DIR=$(eval echo "~$TARGET_USER")

# Check if user exists
if ! id "$TARGET_USER" > /dev/null 2>&1; then
  echo "User $TARGET_USER does not exist."
  exit 1
fi

# Update and upgrade the system
echo "Updating and upgrading the system..."
apt update && apt upgrade -y

echo "Installing Polkit components..."
apt install -y policykit-1 polkitd libpolkit-gobject-1-dev libpolkit-gobject-1-0
apt install -y libpolkit-agent-1-0 libpolkit-agent-1-dev gir1.2-polkit-1.0 policykit-1-gnome pkexec

echo "Setting polkit rules..."

# Prompt for username
read -p "Enter your username: " USERNAME

# Define the rules file path
RULES_FILE="/etc/polkit-1/rules.d/49-custom-synaptic-gdebi.rules"

# Create the rule file
sudo bash -c "cat > \"$RULES_FILE\" <<EOF
polkit.permission.addRule(function(action, subject) {
    if ((action.id == \"org.debian.packages.install\" || 
         action.id == \"org.debian.packages.remove\" ||
         action.id == \"org.debian.packages.upgrade\") &&
        subject.user == \"$USERNAME\") {
        return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if ((action.id == \"org.debian.package-synaptic\" || action.id == \"org.debian.package-gdebi\") &&
        subject.user == \"$USERNAME\") {
        return polkit.Result.YES;
    }
});
EOF"

echo "Custom system-wide polkit rules created in $RULES_FILE."
echo "Note: You might need to restart your session or polkit service to apply changes."

echo "Polkit components installed successfully and the rules are set."

# Install necessary packages
echo "Installing packages..."
apt install -y pkexec bspwm sxhkd xorg xinit feh rofi urxvt polybar suckless-tools geany geany-plugins terminator synaptic gdebi bluez blueman nemo xdg-user-dirs xdg-user-dirs-gtk
apt install -y xserver-xorg policykit-1-gnome network-manager network-manager-gnome dialog mtools dosftools lxappearance acpi avahi-daemon acpid gvfs-backends pamixer gnome-power-manager
apt install -y pulseaudio pavucontrol pulsemixer bluefish bluefish-data bluefish-plugins blueman breeze-gtk-theme gtk-3-examples gtk-4-examples gspell-1-tests gtk-sharp2 gtk-sharp2-examples gtk2-engines
apt install -y xbacklight fonts-recommended xclip fonts-font-awesome i3lock-fancy fonts-terminus slop playerctl brightnessctl kitty alacritty w3m lolcat figlet toilet gtk2-engines-aurora gtk2-engines-cleanice
apt install -y papirus-icon-theme light scrot maim dunst xdotool zip unzip libnotify-dev redshift wmctrl gtk2-engines-murrine gtk2.0-examples libadwaita-1-dev libcanberra-gtk-common-dev
apt install -y xbindkeys xvkbd xdo xautomation xinput build-essential gtk2-engines-oxygen gtk2-engines-pixbuf gtk2-engines-sugar libadwaita-1-0 libcanberra-gtk-dev libcanberra-gtk-module
apt install -y libcanberra-gtk0 libcanberra-gtk3-0 libcanberra-gtk3-dev libchamplain-gtk-0.12-0 pulseaudio-module-gsettings pulseaudio-module-bluetooth gstreamer1.0-alsa gstreamer1.0-gl
apt install -y gstreamer1.0-gtk3 gstreamer1.0-libav gstreamer1.0-packagekit gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-plugins-base-apps gstreamer1.0-plugins-good
apt install -y gstreamer1.0-plugins-rtp gstreamer1.0-plugins-ugly gstreamer1.0-pulseaudio gstreamer1.0-tools gstreamer1.0-vaapi gstreamer1.0-x curl wget mpd mpv sysvinit-utils tar util-linux
apt install -y passwd base-passwd accountsservice adduser coreutils base-files bsdutils dash debianutils diffutils findutils grep gzip hostname init-system-helpers libc-bin login ncurses-base ncurses-bin perl-base sed

# Build directories and enable services
xdg-user-dirs-update
sleep 2
xdg-user-dirs-gtk-update
sleep 2
systemctl enable bluetooth
sleep 2
systemctl enable avahi-daemon
sleep 2
systemctl enable acpid

# Create configuration directories for various applications
echo "Creating configuration directories for $TARGET_USER..."

sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/bspwm"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/sxhkd"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/rofi"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/polybar"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/dunst"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/mpd"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/mpv"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/alacritty"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/kitty"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/geany"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/qt5ct"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/qt6ct"
sudo -u "$TARGET_USER" mkdir -p "$HOME_DIR/.config/pulse"

# Create bspwmrc
echo "Creating bspwmrc..."
sudo -u "$TARGET_USER" bash -c "cat > \"$HOME_DIR/.config/bspwm/bspwmrc\" <<EOF
#!/bin/sh

# Set monitor tags
bspc monitor -d I II III IV V VI VII VIII IX X

# Appearance settings
bspc config border_width 2
bspc config window_gap 5
bspc config split_ratio 0.5
bspc config focus_follows_pointer true
EOF"
sudo -u "$TARGET_USER" chmod +x "$HOME_DIR/.config/bspwm/bspwmrc"

# Create sxhkdrc
echo "Creating sxhkdrc..."
sudo -u "$TARGET_USER" bash -c "cat > \"$HOME_DIR/.config/sxhkd/sxhkdrc\" <<EOF
# Super + Return: Open terminal
super + Return
    terminator

# Web browser
super + p
    brave

# File manager
super + o
    nemo

# Super + D: Launch dmenu
super + d
    dmenu

# Super + Space: Launch rofi
super + space
    rofi -show run

# Super + Q: Close focused window
super + q
    bspc node -c
EOF"

# Create .xinitrc
echo "Creating .xinitrc..."
sudo -u "$TARGET_USER" bash -c "echo 'exec bspwm' > \"$HOME_DIR/.xinitrc\""
sudo -u "$TARGET_USER" chmod +x "$HOME_DIR/.xinitrc"

echo "Installation and configuration for user $TARGET_USER complete!"
echo "Switch to user and run 'startx' to start bspwm."

# Lightdm installation script
echo "Preparing for LightDM install..."
chmod +x root-lightdm.sh
echo "Running LightDM install..."
./root-lightdm.sh
