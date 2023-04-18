#!/bin/bash

################################################################################
#   "                    m           ""#    ""#          #######################
# mmm    m mm    mmm   mm#mm   mmm     #      #    m   m #######################
#   #    #"  #  #   "    #    "   #    #      #    "m m" #######################
#   #    #   #   """m    #    m"""#    #      #     #m#  #######################
# mm#mm  #   #  "mmm"    "mm  "mm"#    "mm    "mm   "#   #######################
#                                                   m"   #######################
#                                                  ""    #######################
################################################################################

# Global variables #############################################################

# OS data
OS_NAME=$(grep '^NAME=' /etc/os-release | cut -d= -f2 | tr -d '"');
OS_PRETTY_NAME=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"');
OS_IS_DEBIAN_BASED=false;
OS_IS_RHEL_BASED=false;
OS_IS_SUSE_BASED=false;

# Packages file
PACKAGES_FILE="$HOME/.instally/package.json";

# Packages
PACKAGES_INSTALLED=0;
APT_IS_UPDATED=false;
SNAPS="";

# UI
GUM_CHOOSE_CURSOR="▶";
GUM_CHOOSE_CURSOR_PREFIX="·";
GUM_CHOOSE_SELECTED_PREFIX="x";
GUM_CHOOSE_UNSELECTED_PREFIX="·";

# Colors
COLOR_ACTIVE="#E60000";
COLOR_ACCENT="#2CB0C4";
GUM_CHOOSE_CURSOR_FOREGROUND="$COLOR_ACTIVE";
GUM_CHOOSE_SELECTED_FOREGROUND="$COLOR_ACCENT";
GUM_CONFIRM_SELECTED_BACKGROUND="$COLOR_ACTIVE";

# Delimiter
DELIMITER="|";
IFS="$DELIMITER";

# Printing #####################################################################

# print_title
# Prints install+'s title.
print_title () {
  printf "\n";
  printf "$(gum style --italic '        welcome to')\n";
  printf "   \"                    m           \"\"#    \"\"#          \n";
  printf " mmm    m mm    mmm   mm#mm   mmm     #      #    m   m\n";
  printf "   #    #\"  #  #   \"    #    \"   #    #      #    \"m m\" \n";
  printf "   #    #   #   \"\"\"m    #    m\"\"\"#    #      #     #m#  \n";
  printf " mm#mm  #   #  \"mmm\"    \"mm  \"mm\"#    \"mm    \"mm   \"#  \n";
  printf "                                                   m\"   \n";
  printf "                                                  \"\"    \n";
}

print_os () {
  printf "$(gum style --bold 'OS:') $OS_PRETTY_NAME\n"
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
  case $SELECTED in
    "Install Packages")
      menu_select_groups;
      ;;
    "Settings")
      menu_settings;
      ;;
    "Quit")
      exit 0;
      ;;
    *)
      exit 1;
      ;;
  esac
}

# Settings menu where `instally` can be configured.
menu_settings () {
  msg_error "To be complete.";
}

# Prompts user to select package groups and provides instructions.
# Associated with `menu_select_groups`.
prompt_select_groups () {
  printf "\n";
  printf "$(gum style --bold --underline 'Select Groups')\n";
  printf "$(gum style --italic 'Press ')";
  printf "$(gum style --bold --foreground '#E60000' 'x')";
  printf "$(gum style --italic ' to select package groups')\n";
  printf "$(gum style --italic 'press ')"
  printf "$(gum style --bold --foreground '#E60000' 'a')";
  printf "$(gum style --italic ' to select all')\n"
  printf "$(gum style --italic 'press ')"
  printf "$(gum style --bold --foreground '#E60000' 'enter')"
  printf "$(gum style --italic ' to confirm your selection:')\n"
}

# Menu used to select groups of packages for installation.
# Invokes `menu_package_select` after user selects (or doesn't select)
# groups of packages.
menu_select_groups () {
  PACKAGES_INSTALLED=0;
  check_packages_file;
  HAS_GROUPS=$(jq 'has("groups")' $PACKAGES_FILE);
  if [ "$HAS_GROUPS" = "true" ]; then
    prompt_select_groups;
    PACKAGE_GROUPS=$(jq -r '.groups | map(.group)[]' $PACKAGES_FILE | \
      gum choose \
      --cursor.foreground="$GUM_CHOOSE_CURSOR_FOREGROUND" \
      --selected.foreground="$GUM_CHOOSE_SELECTED_FOREGROUND" \
      --cursor="$GUM_CHOOSE_CURSOR " \
      --cursor-prefix="$GUM_CHOOSE_CURSOR_PREFIX " \
      --selected-prefix="$GUM_CHOOSE_SELECTED_PREFIX " \
      --unselected-prefix="$GUM_CHOOSE_UNSELECTED_PREFIX " \
      --no-limit);
    PACKAGE_GROUPS_ARRAY=();
    readarray -t PACKAGE_GROUPS_ARRAY <<< "$PACKAGE_GROUPS"
    if [ "${#PACKAGE_GROUPS_ARRAY[@]}" -eq 1 ] \
      && [[ ${PACKAGE_GROUPS_ARRAY[0]} == "" ]]; then
      menu_install_packages;
    else
      menu_install_packages "${PACKAGE_GROUPS_ARRAY[@]}";
    fi
  else
    menu_install_packages;
  fi
}

# Prompts user to select package groups and provides instructions.
# Associated with `menu_select_groups`.
prompt_install_packages () {
  printf "\n"
  printf "$(gum style --bold --underline 'Install Packages')\n";
  printf "$(gum style --italic 'Press ')";
  printf "$(gum style --bold --foreground '#E60000' 'x')";
  printf "$(gum style --italic ' to select packages to install')\n";
  printf "$(gum style --italic 'press ')"
  printf "$(gum style --bold --foreground '#E60000' 'a')";
  printf "$(gum style --italic ' to select all')\n";
  printf "$(gum style --italic 'press ')";
  printf "$(gum style --bold --foreground '#E60000' 'enter')";
  printf "$(gum style --italic ' to confirm your selection:')\n";
}

get_grouped_menu_items () {
  local GROUPS_ARRAY=("$@");
  local MENU_ITEMS_ARRAY=();
  local GROUP_COUNT=0;
  for GROUP in "${GROUPS_ARRAY[@]}"; do
    ((GROUP_COUNT++));
    # Create an array of packages in that group,
    PACKAGES_IN_GROUP=$(jq -r --arg GROUP "$GROUP" \
      '.groups | map(select(.group == $GROUP))[0].packages' \
      $PACKAGES_FILE);
    # And if the array isn't empty,
    if ! [[ "$PACKAGES_IN_GROUP" == "null" ]]; then
      local MENU_ITEMS_FROM_GROUP=$(get_menu_items_from_array "${PACKAGES_IN_GROUP[@]}");
      MENU_ITEMS_ARRAY+=( "${MENU_ITEMS_FROM_GROUP[@]}" );
    fi
  done
  echo "${MENU_ITEMS_ARRAY[@]}";
}

get_ungrouped_menu_items () {
  local MENU_ITEMS_ARRAY=();
  local UNGROUPED_PACKAGES=$(jq -r '.packages' \
    $PACKAGES_FILE);
  if ! [[ "$UNGROUPED_PACKAGES" == "null" ]]; then
    local UNGROUPED_MENU_ITEMS=$(get_menu_items_from_array "${UNGROUPED_PACKAGES[@]}");
    MENU_ITEMS_ARRAY+=( "${UNGROUPED_MENU_ITEMS[@]}" );
  fi
  #echo "${MENU_ITEMS_ARRAY[@]}";
  printf '%s\n' "${MENU_ITEMS_ARRAY[@]}";
}

get_menu_items_from_array () {
  local ARRAY=("$@");
  local ARRAY_LENGTH=$(echo "$ARRAY" | \
    jq 'length');
  local MENU_ITEMS_ARRAY=();
  for (( i=0; i<$ARRAY_LENGTH; i++ )); do
    local PACKAGE=$(echo "$ARRAY" | \
      jq --argjson INDEX $i '.[$INDEX]');
    PACKAGE_NAME=$(echo "$PACKAGE" | jq -r '.name');
    PACKAGE_HAS_DESCRIPTION=$(echo "$PACKAGE" | jq -r 'has("description")');
    if [ "$PACKAGE_HAS_DESCRIPTION" = "true" ]; then
      PACKAGE_DESCRIPTION=$(echo "$PACKAGE" | jq -r '.description');
      MENU_ITEM="$(gum style --bold "$PACKAGE_NAME »") $PACKAGE_DESCRIPTION";
      MENU_ITEMS_ARRAY+=("$MENU_ITEM");
    else
      MENU_ITEM="$(gum style --bold "$PACKAGE_NAME")"
      MENU_ITEMS_ARRAY+=("$MENU_ITEM");
    fi
  done
  #echo "${MENU_ITEMS_ARRAY[@]}";
  printf '%s\n' "${MENU_ITEMS_ARRAY[@]}";
}

get_menu_items () {
  local PACKAGES_ARRAY=();
  local GROUPED_PACKAGES=();
  local UNGROUPED_PACKAGES=();
  if ! [ $# -eq 0 ]; then
    local GROUPS_ARRAY=("$@");
    GROUPED_PACKAGES=($(get_grouped_menu_items "${GROUPS_ARRAY[@]}"));
    PACKAGES_ARRAY+=( "${GROUPED_PACKAGES[@]}" );
  fi
  UNGROUPED_PACKAGES=($(get_ungrouped_menu_items));
  PACKAGES_ARRAY+=( "${UNGROUPED_PACKAGES[@]}" );
  printf '%s\n' "${PACKAGES_ARRAY[@]}";
}

# Menu used to select packages for installation.
menu_install_packages () {
  local MENU_ITEMS=($(get_menu_items "$@"));
  IFS=$'\n';
  readarray -t MENU_ITEMS_ARRAY <<< "$MENU_ITEMS";
  IFS="$DELIMITER";
  prompt_install_packages;
  local SELECTED_PACKAGES=$(gum choose --no-limit \
    --cursor.foreground="$GUM_CHOOSE_CURSOR_FOREGROUND" \
    --selected.foreground="$GUM_CHOOSE_SELECTED_FOREGROUND" \
    --cursor="$GUM_CHOOSE_CURSOR " \
    --cursor-prefix="$GUM_CHOOSE_CURSOR_PREFIX " \
    --selected-prefix="$GUM_CHOOSE_SELECTED_PREFIX " \
    --unselected-prefix="$GUM_CHOOSE_UNSELECTED_PREFIX " \
    "${MENU_ITEMS_ARRAY[@]}");
  local SELECTED_PACKAGES_ARRAY=();
  readarray -t SELECTED_PACKAGES_ARRAY <<< "$SELECTED_PACKAGES";
  if [ "${#SELECTED_PACKAGES_ARRAY[@]}" -eq 1 ] \
    && [[ ${SELECTED_PACKAGES_ARRAY[0]} == "" ]]; then
    printf "No packages selected.\n"
    menu_main;
  else
    install_packages "${SELECTED_PACKAGES_ARRAY[@]}";
  fi
}

menu_install_more_packages () {
  INSTALL_MORE=$(gum confirm "Install more packages?" \
    --selected.background="$GUM_CONFIRM_SELECTED_BACKGROUND");
  if [ $? == 0 ]; then
    menu_select_groups;
  else
    menu_main;
  fi
}

# OS Detection #################################################################
# Functions related to detecting the OS in order to determine the default
# package manager available.

os_is_debian_based () {
  if \
    [ "$OS_NAME" = "Pop!_OS" ] || \
    [ "$OS_NAME" = "Ubuntu" ] || \
    [ "$OS_NAME" = "Debian GNU/Linux" ] || \
    [ "$OS_NAME" = "Linux Mint" ] || \
    [ "$OS_NAME" = "elementary OS" ] || \
    [ "$OS_NAME" = "Zorin OS" ] || \
    [ "$OS_NAME" = "MX Linux" ] || \
    [ "$OS_NAME" = "Raspberry Pi OS" ] || \
    [ "$OS_NAME" = "Deepin" ] || \
    [ "$OS_NAME" = "ArcoLinux" ] || \
    [ "$OS_NAME" = "Peppermint Linux" ] || \
    [ "$OS_NAME" = "Bodhi Linux" ]; then
    OS_IS_DEBIAN_BASED=true;
  fi
}

os_is_rhel_based () {
  if \
    [ "$OS_NAME" = "Fedora Linux" ] || \
    [ "$OS_NAME" = "Red Hat Enterprise Linux" ] || \
    [ "$OS_NAME" = "CentOS Linux" ] || \
    [ "$OS_NAME" = "Oracle Linux Server" ] || \
    [ "$OS_NAME" = "Rocky Linux" ] || \
    [ "$OS_NAME" = "AlmaLinux" ] || \
    [ "$OS_NAME" = "OpenMandriva Lx" ] ||\
    [ "$OS_NAME" = "Mageia" ] ; then
    OS_IS_RHEL_BASED=true;
  fi
}

os_is_suse_based () {
  if \
    [ "$OS_NAME" = "openSUSE" ] || \
    [ "$OS_NAME" = "openSUSE Tumbleweed" ] || \
    [ "$OS_NAME" = "SUSE Enterprise Linux Server" ]; then
    OS_IS_SUSE_BASED=true;
  fi
}

check_os () {
  os_is_debian_based;
  os_is_rhel_based;
  os_is_suse_based;
  os_is_unsupported;
}

# Dependencies #################################################################

check_dependencies () {
  if ! package_is_installed curl || ! package_is_installed gum || ! package_is_installed jq; then
    printf "Welcome to instally! You're using $OS.\n";
    printf "We need some dependencies to get started:\n";
    # Install curl:
    if ! package_is_installed curl; then
      msg_dependency_needed "curl";
      if $OS_IS_DEBIAN_BASED; then
        install_package_apt curl curl;
      elif $OS_IS_RHEL_BASED; then
        install_package_dnf curl curl;
      elif $OS_IS_SUSE_BASED; then
        install_package_zypper curl curl;
      fi
    fi
    # Install gum:
    if ! package_is_installed gum; then
      msg_dependency_needed "gum";
      install_dependency_gum;
    fi
    # Install jq:
    if ! package_is_installed jq; then
      msg_dependency_needed "jq";
      if $OS_IS_DEBIAN_BASED; then
        install_package_apt jq jq;
      elif $OS_IS_RHEL_BASED; then
        install_package_dnf jq jq;
      elif $OS_IS_SUSE_BASED; then
        install_package_zypper jq jq;
      fi
    fi
  fi
  if package_is_installed curl && \
    package_is_installed gum && \
    package_is_installed jq; then
    return 0;
  fi
}

# Checks for ~/.instally & ~/.instally/package.json.
# Creates either if they've yet to exist.
check_packages_file () {
  if ! [ -e $HOME/.instally ]; then
    make_instally_dir;
    make_packages_file;
    prompt_edit_packages_file;
    check_packages_file;
  elif ! [ -e $HOME/.instally/package.json ]; then
    make_packages_file;
    prompt_edit_packages_file;
    check_packages_file;
  elif ! [ -s $PACKAGES_FILE ]; then
    msg_empty "package.json" "📒";
    prompt_edit_packages_file;
    check_packages_file;
  else
    return 0;
  fi
}

# File system ##################################################################
# Functions related to the file system.

# Makes ~/.instally and reports this action.
make_instally_dir () {
  mkdir $HOME/.instally;
  msg_created "~/.instally" "📁";
}

# Makes ~/.instally/package.json and reports this action.
make_packages_file () {
  touch $HOME/.instally/package.json;
  msg_created "~/.instally/package.json" "📒";
}

# Prompts user whether they'd like to edit package.json.
prompt_edit_packages_file () {
  printf "$(gum style --italic \
    'To define packages for instally to install, edit') ";
  printf "$(gum style --bold \
    'package.json').\n";
  printf "$(gum style --bold --italic 'Instructions:') ";
  printf "https://github.com/jelizaga/instally/#-packagesjson\n";
  EDIT_PACKAGES_FILE=$(gum confirm \
    "📒 Edit $(gum style --bold 'package.json')?" \
    --selected.background="$GUM_CONFIRM_SELECTED_BACKGROUND");
  if [ $? == 0 ]; then
    if [ -z $EDITOR ]; then
      nano $PACKAGES_FILE;
    elif [ -n $EDITOR ]; then
      $EDITOR $PACKAGES_FILE;
    fi
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

msg_installing () {
  local PACKAGE_NAME=$1;
  local PACKAGE_ID=$2;
  local INSTALLATION_METHOD=$3;
  if ! package_is_installed gum; then
    printf "🌎 Installing $PACKAGE_NAME ($PACKAGE_ID) using $INSTALLATION_METHOD...\n"
  else
    printf "Installing $(gum style --bold "$PACKAGE_NAME") ($(gum style --italic "$PACKAGE_ID")) using $(gum style --bold "$INSTALLATION_METHOD")...";
  fi
}

msg_not_installed () {
  local PACKAGE_NAME=$1;
  if [ -n "$2" ]; then
    local REQUIREMENT=$2;
    if ! package_is_installed gum; then
      printf "❌ $PACKAGE_NAME is required to $REQUIREMENT, but $PACKAGE_NAME is missing.\n";
    else
      printf "❌ $(gum style --bold "$PACKAGE_NAME") is required to $REQUIREMENT, but $PACKAGE_NAME is missing.\n";
    fi
  else
    if ! package_is_installed gum; then
      printf "❌ $PACKAGE_NAME is missing.\n";
    else
      printf "❌ $(gum style --bold "$PACKAGE_NAME") is missing.\n";
    fi
  fi
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

msg_packages_file_missing_field () {
  local FIELD=$1;
  printf "❗ No $(gum style --bold "$FIELD") field found in $(gum style --bold \
    "$PACKAGES_FILE").\n";
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
  if [ -n "$2" ]; then
    local INSTALLATION_METHOD=$2;
    if ! package_is_installed gum; then
      printf "🎁 $PACKAGE_NAME installed via $INSTALLATION_METHOD.\n";
    else
      printf "🎁 $(gum style --bold "$PACKAGE_NAME") installed using $(gum style --bold "$INSTALLATION_METHOD").\n";
    fi
  else
    if ! package_is_installed gum; then
      printf "🎁 $PACKAGE_NAME installed.\n";
    else
      printf "🎁 $(gum style --bold "$PACKAGE_NAME") installed.\n";
    fi
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

# Package installation  ########################################################
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
  for PACKAGE in "${PACKAGES_TO_INSTALL[@]}"; do
    # Capture the actual `PACKAGE_NAME` from the array and remove styling.
    PACKAGE_NAME=$(echo "$PACKAGE" | \
      sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" | \
      awk -F " »" '{print $1}');
    local PACKAGE_DATA="";
    local HAS_UNGROUPED_PACKAGES=$(jq 'has("packages")' $PACKAGES_FILE);
    local HAS_GROUPED_PACKAGES=$(jq 'has("groups")' $PACKAGES_FILE);
    if [ "$HAS_UNGROUPED_PACKAGES" = "true" ]; then
      UNGROUPED_PACKAGE_DATA=$(jq --arg PACKAGE_NAME "$PACKAGE_NAME" \
        '.packages[] | select(.name == $PACKAGE_NAME)' \
        $PACKAGES_FILE);
    fi
    if [ "$HAS_GROUPED_PACKAGES" = "true" ]; then
      GROUPED_PACKAGE_DATA=$(jq --arg PACKAGE_NAME "$PACKAGE_NAME" \
        '.groups[] | select(.packages != null) | .packages[] | select(.name == $PACKAGE_NAME)' \
        $PACKAGES_FILE);
    fi
    if [ -n "$GROUPED_PACKAGE_DATA" ] && [ "$GROUPED_PACKAGE_DATA" != $'\n' ]; then
      PACKAGE_DATA="$GROUPED_PACKAGE_DATA";
    else
      PACKAGE_DATA="$UNGROUPED_PACKAGE_DATA";
    fi
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
  # If an install method exists, install the package.
  if [ -n "$INSTALL_METHOD" ] && [ "$INSTALL_METHOD" != $'\n' ]; then
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
      elif [ "$INSTALL_METHOD" = "snap" ]; then
        install_package_snap "$PACKAGE_ID" "$PACKAGE_NAME";
      elif [ "$INSTALL_METHOD" = "yum" ]; then
        install_package_yum "$PACKAGE_ID" "$PACKAGE_NAME";
      elif [ "$INSTALL_METHOD" = "zypper" ]; then
        install_package_zypper "$PACKAGE_ID" "$PACKAGE_NAME";
      fi
    fi
  else
    msg_cannot_install "$PACKAGE_NAME" "Installation method not found.";
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
  #local PACKAGE_IS_INSTALLED=$(dpkg-query -s $PACKAGE_ID >/dev/null 2>&1);
  if dpkg -s $PACKAGE_ID >/dev/null 2>&1; then
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
      msg_installing "$PACKAGE_NAME" "$PACKAGE_ID" "apt";
      sudo apt-get install -y $PACKAGE_ID;
    else
      gum spin \
        --spinner globe \
        --title "$(msg_installing "$PACKAGE_NAME" "$PACKAGE_ID" "apt")" \
        -- sudo apt-get install -y $PACKAGE_ID;
    fi
    # If package is successfully installed, say so.
    if [ $? == 0 ]; then
      msg_installed "$PACKAGE_NAME" "apt";
      ((PACKAGES_INSTALLED++));
      return 0;
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
  # If dnf isn't installed, try to install dnf.
  if ! package_is_installed dnf; then
    msg_not_installed "dnf" "install $PACKAGE_NAME";
    if $OS_IS_DEBIAN_BASED; then
      install_package_apt "dnf" "dnf";
      if [ $? == 0 ]; then
        install_package_dnf "$PACKAGE_ID" "$PACKAGE_NAME";
      fi
    elif $OS_IS_RHEL_BASED; then
      install_package_yum "$PACKAGE_ID" "$PACKAGE_NAME";
    fi
  else
    if dnf list installed | grep -q "$PACKAGE_ID"; then
      msg_already_installed "$PACKAGE_NAME";
    else
      if ! package_is_installed gum; then
        msg_installing "$PACKAGE_NAME" "$PACKAGE_ID" "dnf";
        sudo dnf install -y $PACKAGE_ID;
      else
        gum spin \
          --spinner globe \
          --title "$(msg_installing "$PACKAGE_NAME" "$PACKAGE_ID" "dnf")" \
          -- sudo dnf install -y $PACKAGE_ID;
      fi
      if [ $? == 0 ]; then
        msg_installed "$PACKAGE_NAME" "dnf";
        ((PACKAGES_INSTALLED++));
        return 0;
      else
        msg_cannot_install "$PACKAGE_NAME";
      fi
    fi
  fi
}

# Installs a package using flatpak package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_flatpak () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  # If flatpak isn't installed, try to install flatpak.
  if ! package_is_installed flatpak; then
    msg_not_installed "flatpak";
    if $OS_IS_DEBIAN_BASED; then
      install_package_apt "flatpak" "flatpak";
      if [ $? == 0 ]; then
        install_package_flatpak "$PACKAGE_ID" "$PACKAGE_NAME";
      fi
    elif $OS_IS_RHEL_BASED; then
      install_package_dnf "flatpak" "flatpak";
      if [ $? == 0 ]; then
        install_package_flatpak "$PACKAGE_ID" "$PACKAGE_NAME";
      fi
    fi
  # Otherwise, try installing the package using flatpak,
  else
    # Check if the package is already installed using flatpak,
    if flatpak list | grep -q "$PACKAGE_ID"; then
      msg_already_installed "$PACKAGE_NAME";
    # Otherwise, install package.
    else
      if ! package_is_installed gum; then
        msg_installing "$PACKAGE_NAME" "$PACKAGE_ID" "flatpak";
        flatpak install -y $PACKAGE_ID;
      else
        gum spin \
          --spinner globe \
          --title "$(msg_installing "$PACKAGE_NAME" "$PACKAGE_ID" "flatpak")" \
          -- flatpak install -y $PACKAGE_ID;
      fi
      # If package is successfully installed, say so.
      if [ $? == 0 ]; then
        msg_installed "$PACKAGE_NAME" "flatpak";
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

install_package_go () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  msg_todo "go installation";
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
  # If snap isn't installed, try to install snap,
  if ! package_is_installed snap; then
    msg_not_installed "snap" "install $PACKAGE_NAME";
    if $OS_IS_DEBIAN_BASED; then
      install_package_apt "snapd";
      if [ $? == 0 ]; then
        install_package_snap "$PACKAGE_ID" "$PACKAGE_NAME";
      fi
    elif $OS_IS_RHEL_BASED; then
      install_package_dnf "snapd";
      if [ $? == 0 ]; then
        install_package_snap "$PACKAGE_ID" "$PACKAGE_NAME";
      fi
    elif $OS_IS_SUSE_BASED; then
      msg_cannot_install "snap" "Try instructions @ https://snapcraft.io/install/$PACKAGE_ID/opensuse#install to install snap and $PACKAGE_NAME.";
    fi
  # Otherwise, try installing the package using snap:
  else
    # Check if the package is already installed using snap,
    if snap list | grep -q "$PACKAGE_ID"; then
      msg_already_installed "$PACKAGE_NAME";
    # And install the package.
    else
      snap install $PACKAGE_ID;
      # If the package was successfully installed, then say so.
      if [ $? == 0 ]; then
        msg_installed "$PACKAGE_NAME" "snap";
        ((PACKAGES_INSTALLED++));
        return 0;
      # Otherwise, tell 'em the package can't be installed.
      else
        msg_cannot_install "$PACKAGE_NAME";
      fi
    fi
  fi
}

# Installs a package using yum package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_yum () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  # If yum is not installed, the package cannot be installed.
  if ! package_is_installed yum; then
    msg_not_installed "yum";
    msg_cannot_install "$PACKAGE_NAME" "yum is the installation method for $PACKAGE_NAME, but yum is not installed.";
  # Otherwise, try installing the package using yum:
  else
    # Check if the package is installed using yum,
    if yum list installed | grep -q "$PACKAGE_ID"; then
      msg_already_installed "$PACKAGE_NAME";
    # And install the package.
    else
      if ! package_is_installed gum; then
        msg_installing "$PACKAGE_NAME" "$PACKAGE_ID" yum;
        sudo yum install -y $PACKAGE_ID;
      else
        gum spin \
          --spinner globe \
          --title "$(msg_installing "$PACKAGE_NAME" "$PACKAGE_ID" "yum")" \
          -- sudo yum install -y $PACKAGE_ID;
      fi
      # If the package was successfully installed, say so.
      if [ $? == 0 ]; then
        msg_installed "$PACKAGE_NAME" "yum";
        ((PACKAGES_INSTALLED++));
        return 0;
      # Otherwise, tell 'em the package can't be installed.
      else
        msg_cannot_install "$PACKAGE_NAME";
      fi
    fi
  fi
}

# Installs a package using zypper package manager.
# Args:
#   `$1` - Valid package ID.
#   `$2` - Package name.
install_package_zypper () {
  local PACKAGE_ID=$1;
  local PACKAGE_NAME=$2;
  # If zypper is not installed, the package cannot be installed.
  if ! package_is_installed zypper; then
    msg_not_installed "zypper";
    msg_cannot_install "$PACKAGE_NAME";
  # Otherwise, try installing the package using zypper:
  else
    # Check if the package is already installed using zypper,
    if zypper pa -i | grep -q "$PACKAGE_ID"; then
      msg_already_installed "$PACKAGE_NAME";
    # And install the package.
    else
      if ! package_is_installed gum; then
        msg_installing "gum" "gum" "zypper";
        sudo zypper install -y $PACKAGE_ID;
      else
        gum spin \
          --spinner globe \
          --title "$(msg_installing "$PACKAGE_NAME" "$PACKAGE_ID" "zypper")" \
          -- sudo zypper install -y $PACKAGE_ID;
      fi
      # If the package was successfully installed, say so.
      if [ $? == 0 ]; then
        msg_installed "$PACKAGE_NAME" "zypper";
        ((PACKAGES_INSTALLED++));
        return 0;
      # Otherwise, tell 'em the package cannot be installed.
      else
        msg_cannot_install "$PACKAGE_NAME";
      fi
    fi
  fi
}

# Installs a package via a given command.
# Args:
#   `$1` - Installation command.
#   `$2` - Package name.
install_package_command () {
  local COMMAND=$1;
  local PACKAGE_NAME=$2;
  msg_warning "Installing $(gum style --bold "$PACKAGE_NAME") using $(gum style --italic 'command').";
  eval $COMMAND;
  # If command exited 0, assume the package was successfully installed.
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

# Installs gum for instally's interactivity.
install_dependency_gum () {
  # If the OS is Debian-based, use apt to install gum;
  if $OS_IS_DEBIAN_BASED; then
    sudo mkdir -p /etc/apt/keyrings;
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list;
    install_package_apt gum gum;
  # If OS is RHEL-based, use dnf or yum to install gum;
  elif $OS_IS_RHEL_BASED; then
    echo "[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key" | sudo tee /etc/yum.repos.d/charm.repo;
    if ! package_is_installed dnf; then
      install_package_yum gum gum;
    else 
      install_package_dnf gum gum;
    fi
  # Otherwise, install go to install gum.
  else
    wget -P ~/Downloads https://github.com/charmbracelet/gum/releases/download/v0.10.0/gum-0.10.0.tar.gz;
    mkdir ~/Downloads/gum;
    tar -zxvf ~/Downloads/gum-0.10.0.tar.gz -C ~/Downloads/gum;
    if ! package_is_installed go; then
      if $OS_IS_SUSE_BASED; then
        install_package_zypper "go" "go";
        if [ $? == 0 ]; then
          export PATH=$PATH:~/go/bin;
          go install ~/Downloads/gum;
        fi
      else
        msg_cannot_install "gum" "instally does not support $OS_NAME.";
      fi
    fi
  fi
}

################################################################################

sudo -v
check_os
check_dependencies
if [ $? == 0 ]; then
  menu_main
fi
