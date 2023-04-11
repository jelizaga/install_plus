#!/bin/bash

# OS data
OS=$(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
OS_IS_DEBIAN_BASED=false
OS_IS_RHEL_BASED=false
OS_IS_SUSE_BASED=false

# Packages file
PACKAGES_FILE="$HOME/.instally/packages.json"

# Packages
PACKAGES_INSTALLED=0
APT_IS_UPDATED=false

# UI
GUM_CHOOSE_CURSOR="▶";
GUM_CHOOSE_CURSOR_PREFIX="·";
GUM_CHOOSE_SELECTED_PREFIX="x";
GUM_CHOOSE_UNSELECTED_PREFIX="·";

# Colors
GUM_CHOOSE_CURSOR_FOREGROUND="#E60000";
GUM_CHOOSE_SELECTED_FOREGROUND="#2CB0C4";
GUM_CONFIRM_SELECTED_BACKGROUND="#E60000";

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
    --cursor="$GUM_CHOOSE_CURSOR " \
    --cursor.foreground="$GUM_CHOOSE_CURSOR_FOREGROUND" \
    --selected.foreground="$GUM_CHOOSE_SELECTED_FOREGROUND" \
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
  printf "\n";
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
  PACKAGE_CATEGORIES=$(jq -r '.categories | map(.category)[]' $PACKAGES_FILE | \
    gum choose \
    --cursor.foreground="$GUM_CHOOSE_CURSOR_FOREGROUND" \
    --selected.foreground="$GUM_CHOOSE_SELECTED_FOREGROUND" \
    --cursor="$GUM_CHOOSE_CURSOR " \
    --cursor-prefix="$GUM_CHOOSE_CURSOR_PREFIX " \
    --selected-prefix="$GUM_CHOOSE_SELECTED_PREFIX " \
    --unselected-prefix="$GUM_CHOOSE_UNSELECTED_PREFIX " \
    --no-limit)
  # Roll `PACKAGE_CATEGORIES` into an array (`PACKAGE_CATEGORIES_ARRAY`):
  PACKAGE_CATEGORIES_ARRAY=();
  readarray -t PACKAGE_CATEGORIES_ARRAY <<< "$PACKAGE_CATEGORIES"
  # Check if no category is selected:
  if [ "${#PACKAGE_CATEGORIES_ARRAY[@]}" -eq 1 ] \
    && [[ ${PACKAGE_CATEGORIES_ARRAY[0]} == "" ]]; then
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
  CATEGORY_COUNT=0;
  for CATEGORY in "${CATEGORIES_ARRAY[@]}"; do
    ((CATEGORY_COUNT++))
    # Create an array of packages in that category,
    PACKAGES_IN_CATEGORY=$(jq -r --arg CATEGORY "$CATEGORY" \
      '.categories | map(select(.category == $CATEGORY))[0].packages' \
      $PACKAGES_FILE);
    # And if the array isn't empty,
    if ! [[ "$PACKAGES_IN_CATEGORY" == "null" ]]; then
      # Add each package JSON object within to the `PACKAGES_ARRAY`
      # and its menu item to `MENU_ITEMS_ARRAY`.
      PACKAGES_IN_CATEGORY_LENGTH=$(echo "$PACKAGES_IN_CATEGORY" | jq 'length');
      for (( i=0; i<$PACKAGES_IN_CATEGORY_LENGTH; i++ )); do
        PACKAGE=$(echo "$PACKAGES_IN_CATEGORY" | \
          jq --argjson INDEX $i '.[$INDEX]');
        if (( $CATEGORY_COUNT==${#CATEGORIES_ARRAY[@]} )) \
          && (( $i==$PACKAGES_IN_CATEGORY_LENGTH - 1)); then
          PACKAGES_ARRAY+=("$PACKAGE");
        else
          PACKAGES_ARRAY+=("$PACKAGE,");
        fi
        PACKAGE_NAME=$(echo "$PACKAGE" | jq -r '.name');
        PACKAGE_HAS_DESCRIPTION=$(echo "$PACKAGE" | jq 'has("description")');
        if [ "$PACKAGE_HAS_DESCRIPTION" = "true" ]; then
          PACKAGE_DESCRIPTION=$(echo "$PACKAGE" | jq -r '.description');
          MENU_ITEM="$(gum style --bold "$PACKAGE_NAME »") $PACKAGE_DESCRIPTION";
          MENU_ITEMS_ARRAY+=("$MENU_ITEM");
        else
          MENU_ITEM="$(gum style --bold "$PACKAGE_NAME")"
          MENU_ITEMS_ARRAY+=("$MENU_ITEM");
        fi
      done
    fi
  done
  MENU_ITEMS_ARRAY_ALPHABETIZED=($(printf '%s\n' "${MENU_ITEMS_ARRAY[@]}" | sort));
  echo "${MENU_ITEMS_ARRAY[@]}";
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
  PACKAGES_TO_INSTALL=$(gum choose --no-limit \
    --cursor.foreground="$GUM_CHOOSE_CURSOR_FOREGROUND" \
    --selected.foreground="$GUM_CHOOSE_SELECTED_FOREGROUND" \
    --cursor="$GUM_CHOOSE_CURSOR " \
    --cursor-prefix="$GUM_CHOOSE_CURSOR_PREFIX " \
    --selected-prefix="$GUM_CHOOSE_SELECTED_PREFIX " \
    --unselected-prefix="$GUM_CHOOSE_UNSELECTED_PREFIX " \
    "${MENU_ITEMS_ARRAY[@]}");
  # Packages are rolled in an array, `PACKAGES_TO_INSTALL_ARRAY`.
  PACKAGES_TO_INSTALL_ARRAY=();
  readarray -t PACKAGES_TO_INSTALL_ARRAY <<< "$PACKAGES_TO_INSTALL";
  # Return to main menu if no packages were selected:
  if [ "${#PACKAGES_TO_INSTALL_ARRAY[@]}" -eq 1 ] \
    && [[ ${PACKAGES_TO_INSTALL_ARRAY[0]} == "" ]]; then
    printf "No packages selected.\n"
    menu_main;
  # Otherwise, install selected packages.
  else
    install_packages "${PACKAGES_TO_INSTALL_ARRAY[@]}";
  fi
}

menu_install_more_packages () {
  INSTALL_MORE=$(gum confirm "Install more packages?" \
    --selected.background="$GUM_CONFIRM_SELECTED_BACKGROUND");
  if [ $? == 0 ]; then
    menu_select_categories;
  else
    menu_main;
  fi
}

# OS Detection #################################################################
# Functions related to detecting the OS in order to determine the default
# package manager available.

os_is_debian_based () {
  if \
    [ "$OS" = "Pop!_OS" ] || \
    [ "$OS" = "Ubuntu" ] || \
    [ "$OS" = "Debian GNU/Linux" ] || \
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
  if ! package_is_installed curl || ! package_is_installed gum || ! package_is_installed jq; then
    printf "Welcome to install+! You're using $OS.\n";
    printf "We need some dependencies to get started:\n";
    # Install curl:
    if ! package_is_installed curl; then
      msg_dependency_needed "curl";
      if $OS_IS_DEBIAN_BASED; then
        install_package_apt curl curl;
      fi
    fi
    # Install gum:
    if ! package_is_installed gum; then
      msg_dependency_needed "gum";
      install_dependency_gum;
      if [ $? == 1 ]; then
        printf "❗ gum could not be installed.";
      else
        msg_installed gum;
      fi
    fi
    # Install jq:
    if ! package_is_installed jq; then
      msg_dependency_needed "jq";
      if $OS_IS_DEBIAN_BASED; then
        install_package_apt jq jq;
      fi
    fi
  fi
  if package_is_installed curl && \
    package_is_installed gum && \
    package_is_installed jq; then
    return 0;
  fi
}

# Checks for ~/.instally & ~/.instally/packages.json.
# Creates either if they've yet to exist.
check_packages_file () {
  if ! [ -e $HOME/.instally ]; then
    make_instally_dir;
    make_packages_file;
    prompt_edit_packages_file;
  elif ! [ -e $HOME/.instally/packages.json ]; then
    make_packages_file;
    prompt_edit_packages_file;
  elif ! [ -s $PACKAGES_FILE ]; then
    msg_empty "packages.json" "📒";
    prompt_edit_packages_file;
  fi
  check_packages_file;
}

# File system ##################################################################
# Functions related to the file system.

# Makes ~/.instally and reports this action.
make_instally_dir () {
  mkdir $HOME/.instally;
  msg_created "~/.instally" "📁";
}

# Makes ~/.instally/packages.json and reports this action.
make_packages_file () {
  touch $HOME/.instally/packages.json;
  msg_created "~/.instally/packages.json" "📒";
}

# Prompts user whether they'd like to edit packages.json.
prompt_edit_packages_file () {
  printf "$(gum style --italic \
    'To define packages for instally to install, edit') ";
  printf "$(gum style --bold \
    'packages.json').\n";
  printf "$(gum style --bold --italic 'Instructions:') ";
  printf "https://github.com/jelizaga/instally/#-packagesjson\n";
  EDIT_PACKAGES_FILE=$(gum confirm \
    "📒 Edit $(gum style --bold 'packages.json')?" \
    --selected.background="$GUM_CONFIRM_SELECTED_BACKGROUND");
  if [ $? == 0 ]; then
    $EDITOR $PACKAGES_FILE;
  else
    menu_main;
  fi 
}

# Messages #####################################################################
# Functions related to printing reusable messages.

msg_dependency_needed () {
  local DEPENDENCY=$1;
  if ! package_is_installed gum; then
    printf "🔩 We need $DEPENDENCY.\n";
  else
    printf "🔩 We need $(gum style --bold "$DEPENDENCY").\n";
  fi
}

msg_not_installed () {
  local PACKAGE_NAME=$1;
  printf "❌ $(gum style --bold "$PACKAGE_NAME") is missing.\n";
}

msg_empty () {
  local ITEM=$1;
  if [ -n "$2" ]; then
    local ICON=$2;
    printf "$ICON $(gum style --bold "$ITEM") is empty.\n";
  else
    printf "❌ $(gum style --bold "$ITEM") is empty.\n";
  fi
}

msg_created () {
  local ITEM=$1;
  local ICON=$2;
  printf "$ICON $(gum style --bold "$ITEM") created.\n";
}

msg_already_installed () {
  local PACKAGE_NAME=$1;
  if ! package_is_installed gum; then
    printf "👍 $PACKAGE_NAME is already installed.\n";
  else
    printf "👍 $(gum style --bold "$PACKAGE_NAME") is already installed.\n";
  fi
}

msg_installed () {
  local PACKAGE_NAME=$1;
  if ! package_is_installed gum; then
    printf "🎁 $PACKAGE_NAME installed.\n";
  else
    printf "🎁 $(gum style --bold "$PACKAGE_NAME") installed.\n";
  fi
}

msg_updated () {
  local PACKAGE_MANAGER=$1;
  if ! package_is_installed gum; then
    printf "✨ $PACKAGE_MANAGER updated.\n";
  else
    printf "✨ $(gum style --italic "$PACKAGE_MANAGER updated.")\n";
  fi
}

msg_cannot_install () {
  local PACKAGE_NAME=$1;
  if [ -n "$2" ]; then
    local REASON=$2;
    if ! package_is_installed gum; then
      printf "❗ $PACKAGE_NAME could not be installed: $REASON\n";
    else
      printf "❗ $(gum style --bold "$PACKAGE_NAME") could not be installed: $REASON\n";
    fi
  else
    if ! package_is_installed gum; then
      printf "❗ $PACKAGE_NAME could not be installed.\n";
    else
      printf "❗ $(gum style --bold "$PACKAGE_NAME") could not be installed.\n";
    fi
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
  COMMAND=$(echo "$PACKAGE_DATA" | jq 'has("command")');
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
    elif [ "$PIP" = "true" ]; then
      INSTALL_METHOD="pip";
    elif [ "$SNAP" = "true" ]; then
      INSTALL_METHOD="snap";
    elif [ "$COMMAND" = "true" ]; then
      INSTALL_METHOD="command";
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
    elif [ "$PIP" = "true" ]; then
      INSTALL_METHOD="pip";
    elif [ "$SNAP" = "true" ]; then
      INSTALL_METHOD="snap";
    elif [ "$COMMAND" = "true" ]; then
      INSTALL_METHOD="command";
    fi
  elif $OS_IS_SUSE_BASED; then
    if [ "$ZYPPER" = "true" ]; then
      INSTALL_METHOD="zypper";
    elif [ "$FLATPAK" = "true" ]; then
      INSTALL_METHOD="flatpak";
    elif [ "$NPM" = "true" ]; then
      INSTALL_METHOD="npm";
    elif [ "$PIP" = "true" ]; then
      INSTALL_METHOD="pip";
    elif [ "$SNAP" = "true" ]; then
      INSTALL_METHOD="snap";
    elif [ "$COMMAND" = "true" ]; then
      INSTALL_METHOD="command";
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
    PACKAGE_NAME=$(echo "$PACKAGE" | \
      sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | \
      awk -F " »" '{print $1}');
    # Get the JSON `PACKAGE_DATA` for the matching `PACKAGE_NAME` from the
    # packages file.
    PACKAGE_DATA=$(jq --arg PACKAGE_NAME "$PACKAGE_NAME" \
      '.categories[] | select(.packages != null) | .packages[] | select(.name == $PACKAGE_NAME)' \
      $PACKAGES_FILE);
    # Install the package.
    install_package "$PACKAGE_DATA";
  done
  msg_packages_installed;
  menu_install_more_packages;
}

# Installs a package given `PACKAGE_DATA` JSON.
# Args:
#   `$1` - JSON `PACKAGE_DATA` specific to a package.
install_package () {
  local PACKAGE_DATA="$1";
  local PACKAGE_NAME=$(echo "$PACKAGE_DATA" | jq -r '.name' | tr -d '\n');
  local INSTALL_METHOD="$(get_install_method "$PACKAGE_DATA" 2>&1)";
  # If the preferred install method is a command, execute the command.
  if [ "$INSTALL_METHOD" = "command" ]; then
    COMMAND=$(echo "$PACKAGE_DATA" | jq -r '.command');
    install_package_command "$COMMAND" "$PACKAGE_NAME";
  # Otherwise, capture the `PACKAGE_ID` for the `INSTALLATION_METHOD`
  # and install the package using said `INSTALLATION_METHOD`.
  else
    local PACKAGE_ID=$(echo "$PACKAGE_DATA" | jq -r --arg INSTALL_METHOD "$INSTALL_METHOD" ".$INSTALL_METHOD.id");
    if [ "$INSTALL_METHOD" = "apt" ]; then
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
      if ! package_is_installed gum; then
        printf "Updating apt...\n";
        sudo apt-get update -y;
        msg_updated "apt";
      else
        gum spin --spinner globe --title \
          "Updating $(gum style --bold "apt")..." \
          -- sudo apt-get update -y;
      fi
      if [ $? == 0 ]; then
        APT_IS_UPDATED=true;
        msg_updated "apt";
      else
        msg_warning "apt could not be updated.";
      fi
    fi
    # And install the package.
    if ! package_is_installed gum; then
      sudo apt-get install -y $PACKAGE_ID;
    else
      gum spin --spinner globe --title "Installing $(gum style --bold "$PACKAGE_NAME") ($(gum style --italic $PACKAGE_ID))..." -- sudo apt-get install -y $PACKAGE_ID;
    fi
    # If package is successfully installed, say so.
    if [ $? == 0 ]; then
      msg_installed "$PACKAGE_NAME";
      ((PACKAGES_INSTALLED++));
    # Otherwise, print error messages.
    elif [ $? == 1 ] || [ $? == 100 ]; then
      msg_cannot_install "$PACKAGE_NAME" "Package not found. Is $(gum style --italic $PACKAGE_ID) the correct id?";
    elif [ $? == 101 ]; then
      msg_cannot_install "$PACKAGE_NAME" "Download interrupted.";
    elif [ $? == 102 ]; then
      msg_cannot_install "$PACKAGE_NAME" "Error encountered while unpacking package.";
    elif [ $? == 103 ]; then
      msg_cannot_install "$PACKAGE_NAME" "Error encountered while configuring package.";
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
  if ! package_is_installed flatpak; then
    msg_not_installed flatpak
    if $OS_IS_DEBIAN_BASED; then
      install_package_apt flatpak;
    elif $OS_IS_RHEL_BASED; then
      install_package_dnf flatpak;
    fi
  else
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
      elif [ $? == 3 ]; then
        msg_cannot_install "$PACKAGE_NAME" "User does not have permission to install packages with Flatpak."
      elif [ $? == 4 ]; then
        msg_cannot_install "$PACKAGE_NAME" "Unresolvable dependencies. Try installing $(gum style --bold "$PACKAGE_NAME") manually.";
      elif [ $? == 5 ]; then
        msg_already_installed "$PACKAGE_NAME";
      elif [ $? == 6 ]; then
        msg_cannot_install "$PACKAGE_NAME" "Incompatible architecture.";
      elif [ $? == 7 ]; then
        msg_cannot_install "$PACKAGE_NAME" "Remote repository unavailable.";
      elif [ $? == 8 ]; then
        msg_cannot_install "$PACKAGE_NAME" "No such remote repository.";
      elif [ $? == 9 ]; then
        msg_cannot_install "$PACKAGE_NAME" "Could not be downloaded from remote repository.";
      fi
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
  msg_warning "Installing $(gum style --bold "$PACKAGE_NAME") via $(gum style --italic 'command').";
  eval $COMMAND;
  #gum spin --spinner globe --title "Installing $(gum style --bold "$PACKAGE_NAME") via $(gum style --italic 'command')..." -- eval $COMMAND;
  if [ $? == 0 ]; then
    msg_installed "$PACKAGE_NAME";
    ((PACKAGES_INSTALLED++));
  else
    msg_warning "The last command exited with non-0 status.";
    printf "  $(gum style --bold "$PACKAGE_NAME") may not have been installed:\n"
    printf "  $(gum style --bold "1.") Check if $(gum style --bold "$PACKAGE_NAME") is installed.\n";
    printf "  $(gum style --bold "2.") Confirm that the $(gum style --bold "$PACKAGE_NAME") installation command in $PACKAGES_FILE is valid.\n";
  fi
}

# Installs curl.
install_dependency_curl () {
  echo "🌎 Installing curl..."
  if $OS_IS_DEBIAN_BASED; then
    sudo apt install curl;
  elif $OS_IS_RHEL_BASED; then
    sudo dnf install curl;
  fi
}

# Installs gum.
install_dependency_gum () {
  echo "🌎 Installing gum..."
  if $OS_IS_DEBIAN_BASED; then
    sudo mkdir -p /etc/apt/keyrings;
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list;
    sudo apt update;
    sudo apt install gum;
  elif $OS_IS_RHEL_BASED; then
    echo "[charm]
    name=Charm
    baseurl=https://repo.charm.sh/yum/
    enabled=1
    gpgcheck=1
    gpgkey=https://repo.charm.sh/yum/gpg.key" | sudo tee /etc/yum.repos.d/charm.repo
    sudo yum install gum;
  else 
    return 1
  fi
}

################################################################################

sudo -v
check_os
check_dependencies
if [ $? == 0 ]; then
  menu_main
fi
