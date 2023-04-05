#!/bin/bash

OS=$(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_IS_DEBIAN_BASED=false
OS_IS_RHEL_BASED=false
OS_IS_SUSE_BASED=false
PACKAGES_FILE="packages.json"
PACKAGES_INSTALLED=0
APT_IS_UPDATED=false
FLATPAK_IS_UPDATED=false

# print_title
# Prints install+'s title.
print_title () {
  printf "\n"
  printf "$(gum style --italic '        welcome to')\n"
  printf "   \"                    m           \"\"#    \"\"#\n"
  printf " mmm    m mm    mmm   mm#mm   mmm     #      #      m\n"
  printf "   #    #\"  #  #   \"    #    \"   #    #      #      #\n"
  printf "   #    #   #   \"\"\"m    #    m\"\"\"#    #      #   \"\"\"#\"\"\"\n"
  printf " mm#mm  #   #  \"mmm\"    \"mm  \"mm\"#    \"mm    \"mm    #\n"
  printf "\n"
}

print_os () {
  printf "$(gum style --bold 'OS:') $OS\n"
}

package_is_installed () {
  command -v $1 >& /dev/null
  if [ $? == 1 ]; then
    false
  else
    true
  fi
} 

# Menus ########################################################################
# `instally`'s system of interactive menus.

# Main menu presented on start-up and at the completion of certain tasks.
menu_main () {
  print_title
  print_os
  printf "\n"
  SELECTED=$(gum choose \
  "Install Packages" \
  "Settings" \
  "Quit");
  if [[ $SELECTED == "Install Packages" ]]; then
    menu_select_categories
  elif [[ $SELECTED == "Settings" ]]; then
    menu_settings
  elif [[ $SELECTED == "Quit" ]]; then
    return 0
  fi
}

# Settings menu where `instally` can be configured.
menu_settings () {
  msg_error "To be complete.";
}

# Menu used to select categories of packages for installation.
# Invokes `menu_package_select` upon selection of categories.
menu_select_categories () {
  check_packages_file;
  printf "$(gum style --bold --underline 'Select Categories')\n";
  printf "$(gum style --italic 'Press ')";
  printf "$(gum style --bold --foreground '#E60000' 'x')";
  printf "$(gum style --italic ' to select package categories')\n";
  printf "$(gum style --italic 'press ')"
  printf "$(gum style --bold --foreground '#E60000' 'a')";
  printf "$(gum style --italic ' to select all')\n"
  printf "$(gum style --italic 'press ')"
  printf "$(gum style --bold --foreground '#E60000' 'enter')"
  printf "$(gum style --italic ' to confirm your selection:')\n"
  PACKAGE_CATEGORIES=$(jq -r '.categories | map(.category_name)[]' packages.json | gum choose --no-limit)
  # Roll `PACKAGE_CATEGORIES` into an array (`PACKAGE_CATEGORIES_ARRAY`):
  PACKAGE_CATEGORIES_ARRAY=();
  readarray -t PACKAGE_CATEGORIES_ARRAY <<< "$PACKAGE_CATEGORIES"
  # Check if no category is selected:
  if [ "${#PACKAGE_CATEGORIES_ARRAY[@]}" -eq 1 ] && [[ ${PACKAGE_CATEGORIES_ARRAY[0]} == "" ]]; then
    printf "No package categories selected.\n"
    menu_main
  else
    menu_install_packages "${PACKAGE_CATEGORIES_ARRAY[@]}"
  fi
}

# Menu used to select packages for installation.
menu_install_packages () {
  local CATEGORIES_ARRAY=("$@");
  # PACKAGES_ARRAY - JSON objects containing individual package details.
  PACKAGES_ARRAY=();
  # MENU_ITEMS_ARRAY - Items as they'll be displayed for installation.
  MENU_ITEMS_ARRAY=();
  # For every category,
  echo "CATEGORIES: ${#CATEGORIES_ARRAY[@]}";
  CATEGORY_COUNT=0;
  for CATEGORY in "${CATEGORIES_ARRAY[@]}"; do
    ((CATEGORY_COUNT++))
    # Create an array of packages in that category,
    PACKAGES_IN_CATEGORY=$(jq -r --arg CATEGORY "$CATEGORY" '.categories | map(select(.category_name == $CATEGORY))[0].packages' packages.json);
    # And if the array isn't empty,
    if ! [[ "$PACKAGES_IN_CATEGORY" == "null" ]]; then
      # Add each package JSON object within to the `PACKAGES_ARRAY`
      # and its menu item to `MENU_ITEMS_ARRAY`.
      PACKAGES_IN_CATEGORY_LENGTH=$(echo "$PACKAGES_IN_CATEGORY" | jq 'length');
      echo $PACKAGES_IN_CATEGORY_LENGTH;
      for (( i=0; i<$PACKAGES_IN_CATEGORY_LENGTH; i++ )); do
        PACKAGE=$(echo "$PACKAGES_IN_CATEGORY" | jq --argjson INDEX $i '.[$INDEX]');
        echo "Category #: $CATEGORY_COUNT / Total categories: ${#CATEGORIES_ARRAY[@]}"
        echo "i: $i / Total packages: $PACKAGES_IN_CATEGORY_LENGTH";
        if (( $CATEGORY_COUNT==${#CATEGORIES_ARRAY[@]} )) && (( $i==$PACKAGES_IN_CATEGORY_LENGTH - 1)); then
          PACKAGES_ARRAY+=("$PACKAGE");
        else
          PACKAGES_ARRAY+=("$PACKAGE,");
        fi
        PACKAGE_NAME=$(echo "$PACKAGE" | jq -r '.name');
        PACKAGE_DESCRIPTION=$(echo "$PACKAGE" | jq -r '.description');
        MENU_ITEM="$(gum style --bold "$PACKAGE_NAME »") $PACKAGE_DESCRIPTION"
        MENU_ITEMS_ARRAY+=("$MENU_ITEM");
      done
    fi
  done
  printf "\n"
  printf "$(gum style --bold --underline 'Install Packages')\n";
  printf "$(gum style --italic 'Press ')";
  printf "$(gum style --bold --foreground '#E60000' 'x')";
  printf "$(gum style --italic ' to select packages to install')\n";
  printf "$(gum style --italic 'press ')"
  printf "$(gum style --bold --foreground '#E60000' 'a')";
  printf "$(gum style --italic ' to select all')\n"
  printf "$(gum style --italic 'press ')"
  printf "$(gum style --bold --foreground '#E60000' 'enter')"
  printf "$(gum style --italic ' to confirm your selection:')\n"
  # User selects packages to install.
  PACKAGES_TO_INSTALL=$(gum choose --no-limit "${MENU_ITEMS_ARRAY[@]}");
  # Packages are rolled in an array, `PACKAGES_TO_INSTALL_ARRAY`.
  PACKAGES_TO_INSTALL_ARRAY=();
  readarray -t PACKAGES_TO_INSTALL_ARRAY <<< "$PACKAGES_TO_INSTALL";
  # Return to main menu if no packages were selected:
  if [ "${#PACKAGES_TO_INSTALL_ARRAY[@]}" -eq 1 ] && [[ ${PACKAGES_TO_INSTALL_ARRAY[0]} == "" ]]; then
    printf "No packages selected.\n"
    menu_main;
  # Otherwise, install selected packages.
  else
    install_packages "${PACKAGES_TO_INSTALL_ARRAY[@]}";
  fi
}

# OS Detection #################################################################
# Functions related to detecting the OS in order to determine the default
# package manager available.

os_is_debian_based () {
  if \
    [ "$OS" = "Pop!_OS" ] || \
    [ "$OS" = "Ubuntu" ] || \
    [ "$OS" = "Debian GNU/Linux"] || \
    [ "$OS" = "Linux Mint" ] || \
    [ "$OS" = "elementary OS" ] || \
    [ "$OS" = "Zorin OS" ] || \
    [ "$OS" = "MX Linux" ] || \
    [ "$OS" = "Raspberry Pi OS" ] || \
    [ "$OS" = "Deepin" ] || \
    [ "$OS" = "ArcoLinux" ] || \
    [ "$OS" = "Peppermint Linux" ] || \
    [ "$OS" = "Bodhi Linux" ]; then
    OS_IS_DEBIAN_BASED=true;
  fi
}

os_is_rhel_based () {
  if \
    [ "$OS" = "Fedora" ] || \
    [ "$OS" = "Red Hat Enterprise Linux" ] || \
    [ "$OS" = "CentOS Linux" ] || \
    [ "$OS" = "Oracle Linux Server" ] || \
    [ "$OS" = "Rocky Linux" ] || \
    [ "$OS" = "AlmaLinux" ] || \
    [ "$OS" = "OpenMandriva Lx" ] ||\
    [ "$OS" = "Mageia" ] ; then
    OS_IS_RHEL_BASED=true;
  fi
}

os_is_suse_based () {
  if \
    [ "$OS" = "OpenSUSE" ] || \
    [ "$OS" = "SUSE Enterprise Linux Server" ]; then
    OS_IS_SUSE_BASED=true;
  fi
}

check_os () {
  os_is_debian_based;
  os_is_rhel_based;
  os_is_suse_based;
}

# Dependencies #################################################################

check_dependencies () {
  if ! package_is_installed gum || ! package_is_installed jq; then
    printf "Welcome to install+! You're using $OS.\n";
    printf "We need some dependencies to get started:\n";
    # Install gum:
    if ! package_is_installed gum; then
      printf "🛠️ We need gum.\n";
      install_dependency_gum;
      if [ $? == 1 ]; then
        printf "❗ gum could not be installed.";
      else
        msg_installed gum;
      fi
    fi
    # Install jq:
    if ! package_is_installed jq; then
      printf "🛠️ We need $(gum style --bold 'jq').\n";
      install_package_apt jq;
    fi
  fi
  if package_is_installed gum && package_is_installed jq; then
    return 0;
  fi
}

check_packages_file () {
  if ! [ -e $PACKAGES_FILE ]; then
    printf "\n"
    printf "⚠️  $(gum style --bold 'packages.json') not found.\n"
    printf "$(gum style --italic 'Please select a valid ')"
    printf "$(gum style --bold 'packages.json')"
    printf "$(gum style --italic ' file:')\n"
  fi
}

# Messages #####################################################################
# Functions related to printing reusable messages.

msg_not_installed () {
  local PACKAGE_NAME=$1;
  printf "❌ $(gum style --bold "$PACKAGE_NAME") is missing.\n"
}

msg_already_installed () {
  local PACKAGE_NAME=$1;
  printf "👍 $(gum style --bold "$PACKAGE_NAME") is already installed.\n";
}

msg_installed () {
  local PACKAGE_NAME=$1;
  printf "🎁 $(gum style --bold "$PACKAGE_NAME") installed.\n"
}

msg_updated () {
  local PACKAGE_MANAGER=$1;
  printf "✨ $(gum style --italic "$PACKAGE_MANAGER updated.")\n"
}

msg_cannot_install () {
  local PACKAGE_NAME=$1;
  if [ -n "$2" ]; then
    local REASON=$2;
    printf "❗ $(gum style --bold "$PACKAGE_NAME") could not be installed: $REASON\n"
  else
    printf "❗ $(gum style --bold "$PACKAGE_NAME") could not be installed.\n"
  fi
}

msg_packages_installed () {
  if [ $PACKAGES_INSTALLED  -gt 1 ]; then
    printf "🏡🚛 $PACKAGES_INSTALLED packages installed.\n"
  elif [ $PACKAGES_INSTALLED -eq 1 ]; then
    printf "🏡🚚 One package installed.\n"
  else
    printf "🏡🛻 No packages installed.\n"
  fi
}

msg_error () {
  local MESSAGE=$1;
  printf "🐛 $(gum style --bold 'Error:') $MESSAGE\n";
}

msg_warning () {
  local MESSAGE=$1;
  printf "⚠️ $(gum style --bold 'Warning:') $MESSAGE\n";
}

msg_todo () {
  if [ -n "$1" ]; then
    local FEATURE=$1;
    printf "🚧 $FEATURE is under construction.\n";
  else
    printf "🚧 Under construction.\n";
  fi
}

# Package Installation  ########################################################
# Functions related to installing packages.

# Determines and `echo`s the install method of a package, given `PACKAGE_DATA`
# JSON.
# Args:
#   `$1` - JSON `PACKAGE_DATA` specific to a package.
get_install_method () {
  local PACKAGE_DATA="$1";
  local INSTALL_METHOD="";
  APT=$(echo "$PACKAGE_DATA" | jq 'has("apt")');
  DNF=$(echo "$PACKAGE_DATA" | jq 'has("dnf")');
  FLATPAK=$(echo "$PACKAGE_DATA" | jq 'has("flatpak")');
  NPM=$(echo "$PACKAGE_DATA" | jq 'has("npm")');
  PIP=$(echo "$PACKAGE_DATA" | jq 'has("pip")');
  SNAP=$(echo "$PACKAGE_DATA" | jq 'has("snap")');
  YUM=$(echo "$PACKAGE_DATA" | jq 'has("yum")');
  ZYPPER=$(echo "$PACKAGE_DATA" | jq 'has("zypper")');
  HAS_PREFERRED_INSTALL_METHOD=$(echo "$PACKAGE_DATA" | jq 'has("prefer")');
  if [ "$HAS_PREFERRED_INSTALL_METHOD" = "true" ]; then
    INSTALL_METHOD=$(echo "$PACKAGE_DATA" | jq -r '.prefer');
  elif $OS_IS_DEBIAN_BASED; then
    if [ "$APT" = "true" ]; then
      INSTALL_METHOD="apt";
    elif [ "$FLATPAK" = "true" ]; then
      INSTALL_METHOD="flatpak";
    elif [ "$NPM" = "true" ]; then
      INSTALL_METHOD="npm";
    elif [ "$PIP" = "true"]; then
      INSTALL_METHOD="pip";
    elif [ "$SNAP" = "true" ]; then
      INSTALL_METHOD="snap";
    fi
  elif $OS_IS_RHEL_BASED; then
    if [ "$DNF" = "true" ]; then
      INSTALL_METHOD="dnf";
    elif [ "$YUM" = "true" ]; then
      INSTALL_METHOD="yum";
    elif [ "$FLATPAK" = "true" ]; then
      INSTALL_METHOD="flatpak";
    elif [ "$NPM" = "true" ]; then
      INSTALL_METHOD="npm";
    elif [ "$PIP" = "true"]; then
      INSTALL_METHOD="pip";
    elif [ "$SNAP" = "true" ]; then
      INSTALL_METHOD="snap";
    fi
  elif $OS_IS_SUSE_BASED; then
    if [ "$ZYPPER" = "true" ]; then
      INSTALL_METHOD="zypper";
    elif [ "$FLATPAK" = "true" ]; then
      INSTALL_METHOD="flatpak";
    elif [ "$NPM" = "true" ]; then
      INSTALL_METHOD="npm";
    elif [ "$PIP" = "true"]; then
      INSTALL_METHOD="pip";
    elif [ "$SNAP" = "true" ]; then
      INSTALL_METHOD="snap";
    fi
  fi
  echo "$INSTALL_METHOD";
}


# Installs packages given an array of package names.
# Args:
#   `$@` - Array of packages to install.
install_packages () {
  local PACKAGES_TO_INSTALL=("$@");
  # For every PACKAGE...
  for PACKAGE in "${PACKAGES_TO_INSTALL_ARRAY[@]}"; do
    # Capture the actual `PACKAGE_NAME` from the array and remove styling.
    PACKAGE_NAME=$(echo "$PACKAGE" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | awk -F " »" '{print $1}');
    # Get the JSON `PACKAGE_DATA` for the matching `PACKAGE_NAME` from the
    # packages file.
    PACKAGE_DATA=$(jq --arg PACKAGE_NAME "$PACKAGE_NAME" '.categories[] | select(.packages != null) | .packages[] | select(.name == $PACKAGE_NAME)' packages.json);
    # Install the package.
    install_package "$PACKAGE_DATA";
  done
  msg_packages_installed;
}

# Installs a package given `PACKAGE_DATA` JSON.
# Args:
#   `$1` - JSON `PACKAGE_DATA` specific to a package.
install_package () {
  local PACKAGE_DATA="$1";
  local PACKAGE_NAME=$(echo "$PACKAGE_DATA" | jq -r '.name' | tr -d '\n');
  local INSTALL_METHOD="$(get_install_method "$PACKAGE_DATA" 2>&1)";
  local PACKAGE_ID=$(echo "$PACKAGE_DATA" | jq -r --arg INSTALL_METHOD "$INSTALL_METHOD" ".$INSTALL_METHOD.id");
  #printf "\n";
  #printf "$(gum style --bold "$PACKAGE_NAME")\n";
  #printf "$(gum style --italic 'Data:')\n";
  #printf "$PACKAGE_DATA\n";
  #printf "$(gum style --italic 'Install method:') $INSTALL_METHOD\n";
  #printf "$(gum style --italic 'Package ID:') $PACKAGE_ID\n";
  # If the preferred install method is a command, execute the command;
  if [ "$INSTALL_METHOD" = "command" ]; then
    COMMAND=$(echo "$PACKAGE_DATA" | jq '.command');
    install_package_command "$COMMAND" "$PACKAGE_NAME";
  elif [ "$INSTALL_METHOD" = "apt" ]; then
    install_package_apt "$PACKAGE_ID" "$PACKAGE_NAME";
  elif [ "$INSTALL_METHOD" = "dnf" ]; then
    install_package_dnf "$PACKAGE_ID" "$PACKAGE_NAME";
  elif [ "$INSTALL_METHOD" = "flatpak" ]; then
    install_package_flatpak "$PACKAGE_ID" "$PACKAGE_NAME";
  elif [ "$INSTALL_METHOD" = "npm" ]; then
    install_package_npm "$PACKAGE_ID" "$PACKAGE_NAME";
  elif [ "$INSTALL_METHOD" = "pip" ]; then
    install_package_pip "$PACKAGE_ID" "$PACKAGE_NAME";
  elif [ "$INSTALL_METHOD" = "yum" ]; then
    install_package_yum "$PACKAGE_ID" "$PACKAGE_NAME";
  elif [ "$INSTALL_METHOD" = "zypper" ]; then
    install_package_zypper "$PACKAGE_ID" "$PACKAGE_NAME";
  fi
}

# Installs a package using apt package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_apt () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  # If package is already installed, say so.
  if dpkg-query -W $PACKAGE_ID 2>/dev/null | grep -q "^$PACKAGE_ID"; then
    msg_already_installed "$PACKAGE_NAME";
  # Otherwise,
  else
    # Update apt if it isn't already updated,
    if ! $APT_IS_UPDATED; then
      gum spin --spinner globe --title "Updating $(gum style --bold "apt")..." -- sudo apt-get update -y;
      APT_IS_UPDATED=true;
      msg_updated "apt";
    fi
    # And install the package.
    gum spin --spinner globe --title "Installing $(gum style --bold "$PACKAGE_NAME") ($(gum style --italic $PACKAGE_ID))..." -- sudo apt-get install -y $PACKAGE_ID;
    # If package is successfully installed, say so.
    if [ $? == 0 ]; then
      msg_installed "$PACKAGE_NAME";
      ((PACKAGES_INSTALLED++));
    # Otherwise, print error messages.
    elif [ $? == 1 ]; then
      msg_cannot_install "$PACKAGE_NAME" "Package not found. Is $(gum style --italic $PACKAGE_ID) the correct id?";
    elif [ $? == 104 ]; then
      msg_already_installed "$PACKAGE_NAME";
    elif [ $? == 106 ]; then
      msg_cannot_install "$PACKAGE_NAME" "Unsatisfied dependencies.";
    elif [ $? == 130 ]; then
      msg_cannot_install "$PACKAGE_NAME" "Installation interrupted by user.";
    fi
  fi
}

# Installs a package using dnf package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_dnf () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  msg_todo "dnf installation";
}

# Installs a package using flatpak package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_flatpak () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  local ALREADY_INSTALLED=$(flatpak list | grep "$PACKAGE_ID");
  # If package is already installed, say so.
  if flatpak list | grep -q "$PACKAGE_ID"; then
    msg_already_installed "$PACKAGE_NAME";
  # Otherwise, install package.
  else
    gum spin --spinner globe --title "Installing $(gum style --bold "$PACKAGE_NAME") ($(gum style --italic $PACKAGE_ID))..." -- flatpak install -y $PACKAGE_ID;
    # If package is successfully installed, say so.
    if [ $? == 0 ]; then
      msg_installed "$PACKAGE_NAME";
      ((PACKAGES_INSTALLED++));
    # Otherwise, print error messages.
    elif [ $? == 1 ]; then
      msg_cannot_install "$PACKAGE_NAME" "Installation interrupted by user.";
    elif [ $? == 5 ]; then
      msg_already_installed "$PACKAGE_NAME";
    fi
  fi
}

# Installs a package using npm package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_npm () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  msg_todo "npm installation";
  #gum spin --spinner globe --title "Installing $(gum style --bold $1)..." npm install $1
  #npm install $1 >& /dev/null
}

# Installs a package using pip package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_pip () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  msg_todo "pip installation";
}

# Installs a package using snap package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_snap () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  msg_todo "snap installation";
  #gum spin --spinner globe --title "Installing $1..." -- snap install $1
  #snap install $1
}

# Installs a package using yum package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_yum () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  msg_todo "yum installation";
}

# Installs a package using zypper package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_zypper () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  msg_todo "zypper installation";
}

# Installs a package via a given command.
# Args:
#   `$1` - Installation command.
#   `$2` - Package name.
install_package_command () {
  local COMMAND=$1;
  local PACKAGE_NAME=$2;
  msg_warning "Installing $(gum style --bold $PACKAGE_NAME) via $(gum style --italic 'command').";
  eval $COMMAND;
}

# Installs gum.
install_dependency_gum () {
  echo "🌎 Installing gum..."
  if $OS_IS_DEBIAN_BASED; then
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt update && sudo apt install gum
  elif $OS_IS_RHEL_BASED; then
    echo "[charm]
    name=Charm
    baseurl=https://repo.charm.sh/yum/
    enabled=1
    gpgcheck=1
    gpgkey=https://repo.charm.sh/yum/gpg.key" | sudo tee /etc/yum.repos.d/charm.repo
    sudo yum install gum
  else 
    return 1
  fi
}

# Installs d2.
install_dependency_d2 () {
  curl -fsSL https://d2lang.com/install.sh | sh -s --
}

# verify_package_installed #####################################################
# Returns 1 if package is missing; 0 if found.
# Prints message declaring package status.
# Args:
#   $1 - Package id.
#   $2 - Package manager or method used to install package.
verify_package_installed () {
  if [ $2 == apt ]; then
    dpkg -s $1 >& /dev/null
  elif [ $2 == flatpak ]; then
    flatpak info $1 >& /dev/null
  elif [ $2 == snap ]; then
    snap list $1 >& /dev/null
  elif [ $2 == npm ]; then
    npm ls $1 >& /dev/null
  fi
  if [ $? == 1 ]; then
    printf "❌ $1 is missing.\n"
    return 1
  else
    printf "👍 $1 is already installed.\n"
    return 0
  fi
}

# verify_package_available #####################################################
# Returns 0 if package is available for installation; 1 if unavailable.


################################################################################

sudo -v
check_os
check_dependencies
if [ $? == 0 ]; then
  menu_main
fi
