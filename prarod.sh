#!/bin/sh

# Installing my stuffs.
# Requirements:
# - internet
# - arch linux
# - curl
# - run as root user


usage() { >&2 echo "./enlil [-o] [-d]" ; exit 1 ; }

if [ -z "$1" ] ; then
    [ "$1" ] || usage && exit 1
fi

# TEMP VARIABLES
dest_user="darko"
dest_home="/home/$dest_user"
aur_helper="yay"

# cpu
CPU_CORES=$(cat /proc/cpuinfo | grep "processor" | wc -l)

# Package array
declare -a warez=("base-devel" "git" "firefox" "xorg" "obconf" "aria2" "zsh" "xorg-xinit" "xterm" "neovim" "tmux" "ranger" "terminus-font" "exa" "fzf" "ripgrep" "noto-fonts-emoji" "pcmanfm" "nitrogen" "figlet" "lolcat" "wget" "conky")
declare -a openbox_warez=("openbox" "obconf" "lxappearance-obconf")
declare -a dwm_warez=("xorg-xsetroot" "dmenu" "rofi")

# Functions

function welcome(){
	dialog --title "Welcome!" --msgbox "Welcome to Prarod!\\nThe only script to properly configure your Arch distribution the way Darko likes it!" 10 60
	dialog --colors --title "Important Note!" --yes-label "All ready!" --no-label "Return..." --yesno "Be sure the computer you are using has current pacman updates and refreshed Arch keyrings.\\n\\nIf it does not, the installation of some programs might fail." 8 70
}

function msgbox(){
	dialog --title "$1" --msgbox "$2" 10 60
}

function pacinstall(){
	pacman --noconfirm --needed -S "$1" > /dev/null 2>&1
}
function updatepac(){
	## Update pacman
	echo "=== Updating pacman ==="
	pacman -Syy && pacman --quiet --noconfirm -Syu
}

function baseutilinstall(){
	## Install utilities - just before yay
	echo "=== Installing base utilities ===" 
        pacman --noconfirm -S git base-devel dialog
}

function xinitconfig(){
	cp /etc/X11/xinit/xinitrc $dest_home/.xinitrc
	chown $dest_user:$dest_user $dest_home/.xinitrc
        #sudo -u $dest_user chmod 644 $dest_home/.xinitrc
	sudo -u $dest_user head -n-5 $dest_home/.xinitrc > $dest_home/tmpx
        sudo -u $dest_user mv $dest_home/tmpx $dest_home/.xinitrc

	if [[ "$1" == "openbox" ]]; then
	       	echo "exec openbox-session" >> $dest_home/.xinitrc
	elif [[ "$1" == "dwm" ]]; then
	       	echo "exec dwm" >> $dest_home/.xinitrc
        fi
}
function aurmanual(){
	TEMP_DIR=$(mktemp -d)
	cd $TEMP_DIR
	git clone https://aur.archlinux.org/"$1".git > /dev/null 2>&1
	cd "$1"
	chown -R $dest_user:$dest_user $TEMP_DIR
	dialog --title "Manual AUR package installation" --infobox "Installing \`$1\` on the current system." 5 70
	sudo -u "$dest_user" makepkg --noconfirm -si > /dev/null 2>&1
}

function aurhelper(){
	yes | sudo -u $dest_user $aur_helper -S $1 > /dev/null 2>&1
}

function usershell(){
	chsh -s $(which zsh) $1 > /dev/null 2>&1
	# Install ohmyzsh
        sudo -u $dest_user sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

function configuremakepkg(){
	sed -i '/#MAKEFLAGS=*/ s/#MAKEFLAGS=.*/MAKEFLAGS="-j'$CPU_CORES'"/' /etc/makepkg.conf
}
function configurepacman(){
	# add some colors to your life
	grep -q "^Color" /etc/pacman.conf || sed -i "s/^#Color$/Color/" /etc/pacman.conf
	grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
}

function setuphome(){
	sudo -u $dest_user mkdir -p $dest_home/{dl,pic,tmp,vid,mus,repos}
}
function configurest(){
	cd $dest_home/repos
	sudo -u $dest_user git clone https://github.com/darko-mesaros/st.git
	cd st
	make
	make install
}

function setuplolbanner(){
	sudo -u $dest_user mkdir -p $dest_home/.local/share/fonts/figlet-fonts
	sudo -u $dest_user wget "https://raw.githubusercontent.com/xero/figlet-fonts/master/3d.flf" $dest_home/.local/share/fonts/figlet-fonts/
}

# kick off 
setuphome

## Updating Pacman
updatepac
## Installing dialog as this is needed for all 
pacinstall "dialog"

configuremakepkg
configurepacman


## Welcome Message
welcome || error "Cancelled by user"

## INSTALLING PACMAN PACKAGES
for x in "${warez[@]}"; do
	dialog --title "Enlil package installation" --infobox "Installing \`$x\` on the current system." 5 70
	pacinstall "$x"
done

## Installing the window manager
case $1 in
  -o) 
    msgbox "Window Manager installation" "You have chosen to install OPENBOX as the window manager."
    for x in "${openbox_warez[@]}"; do
            dialog --title "Enlil package installation" --infobox "Installing \`$x\` on the current system." 5 70
            pacinstall "$x"
    done
    sudo -u $dest_user echo "*.font: Terminus:pixelsize=16:antialias=false:autohint=true;" >> $dest_home/.Xresources
    msgbox "Notification!" "I will now configure xinitrc for Openbox"
    xinitconfig "openbox"
    ;;
  -d)
    msgbox "Window Manager installation" "You have chosen to install DWM as the window manager."
    for x in "${dwm_warez[@]}"; do
            dialog --title "Enlil package installation" --infobox "Installing \`$x\` on the current system." 5 70
            pacinstall "$x"
    done
    sudo -u $dest_user git clone https://github.com/darko-mesaros/dwm $dest_home/repos/dwm/
    cd $dest_home/repos/dwm
    make
    sudo make install
    sudo -u $dest_user echo "*.font: Terminus:pixelsize=16:antialias=false:autohint=true;" >> $dest_home/.Xresources
    aurmanual "nerd-fonts-mononoki"
    msgbox "Notification!" "I will now configure xinitrc for DWM"
    xinitconfig "dwm"
    ;;
esac

## Install yay
msgbox "Notification!" "Installing the $aur_helper AUR helper."
aurmanual "$aur_helper"

## AUR PACKAGES
for y in perl-linux-desktopfiles obmenu-generator; do
	dialog --title "AUR package installation" --infobox "Installing \`$y\` on the current system." 5 70
	aurhelper "$y"
done

## installing ST terminal
msgbox "Notification!" "I will not install the Suckless terminal - st"
configurest

## Changing user shell
dialog --colors --title "Shell Change" --yes-label "Yes" --no-label "No" --yesno "Do you wish to change your default shell to ZSH?" 8 70
zsh_response=$?
case $zsh_response in
	0)
		msgbox "Notification!" "Changing user shell to zsh"
		usershell "$dest_user"
		;;
	1) 
		msgbox "Notification!" "Shell not changed"
		;;
	2)
		msgbox "Notification!" "[ESC] key pressed."
		;;
esac

## Lolbanner is important
msgbox "Notification!" "The most important utility of them all - Lolbanner"
setuplolbanner

msgbox "Done" "And we are done! Thank you!"
