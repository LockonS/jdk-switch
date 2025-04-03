# shellcheck disable=SC1090,SC2164,SC2143,SC2010
JDK_SWITCH_SCRIPT_PATH=$(
  cd "$(dirname "$0")"
  pwd
)

_jdk_switch_load_env() {
  JDK_STATUS_FILE_PATH=$JDK_SWITCH_SCRIPT_PATH/status
  JDK_STATUS_FILE=$JDK_STATUS_FILE_PATH/jdk_status

  Blue='\033[0;34m'
  BRed='\033[1;31m'
  BBlue='\033[1;34m'
  BGreen='\033[1;32m'
  NC='\033[0m'

  JS_PLUGIN_NAME="JDK-SWITCH"
}

jdk-switch() {
  local PARAM=$1
  case $PARAM in
    -s | --status | status) jdk-status ;;
    -h | --help | help) _jdk_switch_help_page ;;
    -u | --update | update) _jdk_switch_plugin_update ;;
    -v | --switch | switch) _jdk_switch_switch_jdk "${2}" ;;
    -c | --scan | scan) _jdk_switch_scan ;;
    *) _jdk_switch_switch_jdk "${1}" ;;
  esac
}

jdk-switch-enable() {
  export PATH=$JAVA_HOME/bin:$PATH
}

# display jdk status
jdk-status() {
  if [[ -z $JDK_STATUS ]]; then
    echo -e "${BRed}${JS_PLUGIN_NAME}: JDK status unknown${NC}"
  else
    echo "JAVA_HOME: $JAVA_HOME"
    java -version
  fi
}

# display help page and info
_jdk_switch_help_page() {
  echo -e "jdk-switch zsh plugin\n"
  echo "usage: jdk-switch [-s|--status][-u|--update][-v|--switch code][-c|--scan|scan][-h|--help]"
  echo "       -h, --help, help               Display manual page"
  echo "       -s, --status, status           Display activated jdk status"
  echo "       -u, --update, update           Update jdk-switch plugin with git"
  echo "       -v, --switch, switch  code     Switch to target jdk version"
  if [[ $OSNAME == DARWIN* ]]; then
    echo "       -c, --scan, scan               Scan homebrew installed jdk and create symbolic links for MacOS"
  fi
  echo "       code                           Switch to target jdk version, legacy support"
}

# update jdk-switch plugin
_jdk_switch_plugin_update() {
  echo -e "${Blue}Updating jdk-switch plugin${NC}"
  git -C "$JDK_SWITCH_SCRIPT_PATH" stash
  git -C "$JDK_SWITCH_SCRIPT_PATH" pull
  exec zsh
}

# load different function based on os type
_jdk_switch_load_by_os() {
  OSNAME=$(uname -s | tr "[:lower:]" "[:upper:]")
  if [[ $OSNAME == DARWIN* ]]; then
    _jdk_switch_macos_module
  elif [[ $OSNAME == LINUX* ]]; then
    _jdk_switch_linux_module
  else
    echo -e "${BRed}${JS_PLUGIN_NAME}: Unsupported OS, exiting${NC}"
  fi
}

# save setting to config file and apply setting by reloading shell environment
_jdk_switch_apply_setting() {
  local VERSION_CODE JAVA_HOME_PATH INIT_MODE
  VERSION_CODE=${1}
  JAVA_HOME_PATH=${2}
  INIT_MODE=${3}

  # save configuration to jdk config file
  {
    echo "JDK_STATUS=$VERSION_CODE"
    echo "JAVA_HOME=$JAVA_HOME_PATH"
    echo "PATH=\$JAVA_HOME/bin:\$PATH"
  } >"$JDK_STATUS_FILE"

  # print remind message if jdk was found and activated
  [[ -n $INIT_MODE ]] && echo -e "$JS_PLUGIN_NAME: Activate jdk ${BBlue}${VERSION_CODE}${NC} as default jdk.\nReloading shell..."

  # print jdk version and reload shell
  "$JAVA_HOME_PATH/bin/java" -version
  exec zsh
}

# load saved setting
_jdk_switch_load_config() {
  # create status file and directory if not exist
  [[ ! -d "$JDK_STATUS_FILE_PATH" ]] && mkdir "$JDK_STATUS_FILE_PATH"
  if [[ ! -f "$JDK_STATUS_FILE" ]]; then
    touch "$JDK_STATUS_FILE"
    [[ $OSNAME == DARWIN* ]] && _jdk_switch_scan
  fi

  # apply environment variable in JDK_STATUS_FILE
  source "$JDK_STATUS_FILE" && export JAVA_HOME

  # in case jdk was upgraded by other applications with minor version upgrade, e.g. homebrew
  if [[ ! -d $JAVA_HOME ]]; then
    JDK_PREVIOUS_VERSION=$JDK_STATUS
    unset JDK_STATUS
  fi
}

_jdk_switch_msg_no_target_version() {
  local VERSION_CODE=${1}
  echo -e "${BRed}$JS_PLUGIN_NAME: Target version ${VERSION_CODE} not found ${NC}"
}

_jdk_switch_msg_switch_version() {
  local VERSION_CODE=${1}
  echo -e "$JS_PLUGIN_NAME: Switch to jdk ${BBlue}${VERSION_CODE}${NC}"
}

_jdk_switch_msg_no_jdk_installed() {
  echo -e "${BRed}${JS_PLUGIN_NAME}: No JDK found on this machine${NC}"
}

# validate saved setting in case of empty or corrupted, in that case search an installed jdk and set as default
_jdk_switch_validate_config() {
  [[ -n $JDK_STATUS ]] && return 0

  # if jdk was upgraded in minor version, use previous version to inherit the major version
  if [[ -n $JDK_PREVIOUS_VERSION ]]; then
    # if the major version exist, exit the process with success, else search and apply the default jdk
    _jdk_switch_switch_jdk "$JDK_PREVIOUS_VERSION" && return 0
  fi

  # reload environment only if search operation complete with success
  _jdk_switch_search_default && exec zsh
}

_jdk_switch_macos_module() {
  MACOS_JDK_DIR=/Library/Java/JavaVirtualMachines
  BREW_EXECUTABLE=brew

  # extract version code from jdk home directory
  _jdk_switch_extract_version_code() {
    basename "${1}" | sed 's/openjdk[-@_]*//g;s/[.]*jdk[-]*//g'
  }

  # scan MacOS default jdk directory, remove broken links and create new links for brew installed jdk
  _jdk_switch_scan() {
    local JDK_ENTRY
    # check if MacOS default jdk directory exist and have jdk installed (or sub directories)
    [[ ! -d $MACOS_JDK_DIR ]] && sudo mkdir -p "$MACOS_JDK_DIR"

    # traverse all sub directory, remove broken links
    if [[ -n "$(ls "$MACOS_JDK_DIR")" ]]; then
      for JDK_ENTRY in "$MACOS_JDK_DIR"/*; do
        if [[ ! -e $JDK_ENTRY ]]; then
          echo -e "Broken link deleted for $JDK_ENTRY"
          sudo rm -rf "$JDK_ENTRY"
        fi
      done
    fi

    # if homebrew is installed, check jdk installed by homebrew
    if command -v $BREW_EXECUTABLE &>/dev/null; then
      BREW_OPT_DIR="$(brew --prefix)"/opt
      if [[ -n "$(ls "$BREW_OPT_DIR" | grep 'jdk')" ]]; then
        echo -e "$JS_PLUGIN_NAME: Scanning brew installed jdk"
        # traverse all brew installed jdk and create symbolic link if not created
        for JDK_ENTRY in "$BREW_OPT_DIR"/*jdk@*; do
          JDK_ENTRY_NAME=$(basename "$JDK_ENTRY")
          JDK_LINK=$MACOS_JDK_DIR/$JDK_ENTRY_NAME
          JDK_ENTRY_HOME=$JDK_ENTRY/libexec/openjdk.jdk/Contents/Home
          if [[ ! -L $JDK_LINK ]]; then
            echo -e "$JS_PLUGIN_NAME: Creating symbolic link from [${BGreen}$JDK_ENTRY_HOME${NC}] to [${BGreen}$JDK_LINK${NC}]"
            sudo ln -s "$JDK_ENTRY_HOME" "$JDK_LINK"
          else
            echo -e "$JS_PLUGIN_NAME: Symbolic link [${BGreen}$JDK_LINK${NC}] already exist"
          fi
        done
      fi
    fi

  }

  _jdk_switch_check_if_no_jdk_installed() {
    local BREW_JDK_EXIST MACOS_JDK_EXIST
    BREW_JDK_EXIST=false
    MACOS_JDK_EXIST=false

    # if homebrew is installed, check jdk installed by homebrew
    if command -v $BREW_EXECUTABLE &>/dev/null; then
      BREW_OPT_DIR="$(brew --prefix)"/opt
      if [[ -n "$(ls "$BREW_OPT_DIR" | grep 'jdk')" ]]; then
        BREW_JDK_EXIST=true
      fi
    fi

    # check if MacOS default jdk directory exist and have jdk installed (or sub directories)
    if [[ -d $MACOS_JDK_DIR ]] && [[ -n "$(ls "$MACOS_JDK_DIR")" ]]; then
      MACOS_JDK_EXIST=true
    fi

    if [[ $BREW_JDK_EXIST == false ]] && [[ $MACOS_JDK_EXIST == false ]]; then
      _jdk_switch_msg_no_jdk_installed
      return 1
    fi
  }

  # traverse all installed jdk to find a target jdk
  _jdk_switch_traverse_jdk() {
    local JDK_ENTRY
    # search jdk installed by homebrew first
    if [[ -n "$BREW_OPT_DIR" ]] && [[ -n "$(ls "$BREW_OPT_DIR" | grep 'jdk')" ]]; then
      # traverse homebrew jdk list
      for JDK_ENTRY in "$BREW_OPT_DIR"/*jdk@*; do
        # incase no version exist in the direcotry
        [[ -z "$(ls "$JDK_ENTRY")" ]] && continue
        # check if directory is a valid jdk directory
        JDK_ENTRY_HOME=$JDK_ENTRY/libexec/openjdk.jdk/Contents/Home
        if [[ -f "$JDK_ENTRY_HOME/bin/java" ]]; then
          EXTRACT_VERSION_CODE=$(_jdk_switch_extract_version_code "$JDK_ENTRY")
          MAJOR_VERSION=$(echo "$EXTRACT_VERSION_CODE" | cut -d. -f1)
          if [[ -z $VERSION_CODE ]]; then
            # if version code not provided, select first version and set JAVA_HOME_PATH
            JAVA_HOME_PATH=$JDK_ENTRY_HOME
            break
          else
            # if version code provided, select first matched version and set JAVA_HOME_PATH
            # need some special treatment for jdk before 9
            [[ $VERSION_CODE -lt 9 ]] && MAJOR_VERSION=$(echo "$EXTRACT_VERSION_CODE" | cut -d. -f2)
            if [[ $MAJOR_VERSION == "$VERSION_CODE" ]]; then
              JAVA_HOME_PATH=$JDK_ENTRY_HOME
              break
            fi
          fi
        fi
      done
      # if a brew installed jdk selected, create a link to MacOS default jdk directory
      if [[ -n "$JAVA_HOME_PATH" ]]; then
        JDK_ENTRY_NAME=$(basename "$JDK_ENTRY")
        JDK_LINK=$MACOS_JDK_DIR/$JDK_ENTRY_NAME
        if [[ ! -L "$JDK_LINK" ]]; then
          echo -e "$JS_PLUGIN_NAME: Creating symbolic link for [${BGreen}$JAVA_HOME_PATH${NC}] at [${BGreen}$JDK_LINK${NC}]"
          echo -e "$JS_PLUGIN_NAME: This operation need system admin permission"
          sudo ln -s "$JAVA_HOME_PATH" "$JDK_LINK"
        fi
      fi
    fi

    # if no homebrew jdk found or homebrew not installed, seacrh in MacOS default jdk directory
    if [[ -z "$JAVA_HOME_PATH" ]]; then
      for JDK_ENTRY in "$MACOS_JDK_DIR"/*; do
        # ignore symbolic link
        [[ -L $JDK_ENTRY ]] && continue
        # check if directory is a valid jdk directory
        JDK_ENTRY_HOME=$JDK_ENTRY/Contents/Home
        if [[ -f "$JDK_ENTRY_HOME/bin/java" ]]; then
          # compare version code extract from jdk directory
          EXTRACT_VERSION_CODE=$(_jdk_switch_extract_version_code "$JDK_ENTRY")
          MAJOR_VERSION=$(echo "$EXTRACT_VERSION_CODE" | cut -d. -f1)
          if [[ -z $VERSION_CODE ]]; then
            # if version code not provided, select first version and set JAVA_HOME_PATH
            JAVA_HOME_PATH=$JDK_ENTRY_HOME
            break
          else
            # if version code provided, select first matched version and set JAVA_HOME_PATH
            # need some special treatment for jdk before 9
            [[ $VERSION_CODE -lt 9 ]] && MAJOR_VERSION=$(echo "$EXTRACT_VERSION_CODE" | cut -d. -f2)
            if [[ $MAJOR_VERSION == "$VERSION_CODE" ]]; then
              JAVA_HOME_PATH=$JDK_ENTRY_HOME
              break
            fi
          fi
        fi
      done
    fi
  }

  # search for jdk with designated version code
  _jdk_switch_switch_jdk() {
    local VERSION_CODE JAVA_HOME_PATH EXTRACT_VERSION_CODE MAJOR_VERSION
    VERSION_CODE=${1}

    # check jdk directory incase no jdk is installed
    _jdk_switch_check_if_no_jdk_installed || return 1

    # traverse all jdk to select a target jdk
    _jdk_switch_traverse_jdk "$VERSION_CODE"

    if [[ -n $JAVA_HOME_PATH ]]; then
      _jdk_switch_msg_switch_version "$VERSION_CODE"
      _jdk_switch_apply_setting "$VERSION_CODE" "$JAVA_HOME_PATH"
    else
      # show error message if not in init mode
      _jdk_switch_msg_no_target_version "$VERSION_CODE"
      return 1
    fi
  }

  # search installed jdk and apply the first located one as default
  _jdk_switch_search_default() {
    # check jdk directory incase no jdk is installed
    _jdk_switch_check_if_no_jdk_installed || return 1

    # traverse all jdk to select a target jdk
    _jdk_switch_traverse_jdk "$VERSION_CODE"

    # if a default jdk is selected
    if [[ -n $JAVA_HOME_PATH ]]; then
      _jdk_switch_apply_setting "$MAJOR_VERSION" "$JAVA_HOME_PATH" true
    fi

  }
}

_jdk_switch_linux_module() {
  LINUX_JDK_DIR="/usr/lib/jvm"

  # extract version code from jdk home directory
  _jdk_switch_extract_version_code() {
    basename "${1}" | sed 's/jdk\|jdk-\|java-\|openjdk\|openjdk-\|openjdk@\|\.jdk\|-openjdk-[a-zA-Z0-9_\.\-]*//g'
  }

  _jdk_switch_scan() {
    echo -e "$JS_PLUGIN_NAME: This command is not available on Linux."
  }

  # traverse all installed jdk to find a target jdk
  _jdk_switch_traverse_jdk() {
    local VERSION_CODE=${1}
    for JDK_ENTRY in "$LINUX_JDK_DIR"/*; do
      if [[ ! -L $JDK_ENTRY ]] && [[ -f "$JDK_ENTRY/bin/java" ]]; then
        EXTRACT_VERSION_CODE=$(_jdk_switch_extract_version_code "$JDK_ENTRY")
        if [[ -z $VERSION_CODE ]]; then
          # if version code not provided, select first version and set JAVA_HOME_PATH
          JAVA_HOME_PATH=$JDK_ENTRY
          break
        else
          # if version code provided, select first matched version and set JAVA_HOME_PATH
          if [[ $EXTRACT_VERSION_CODE == "$VERSION_CODE" ]]; then
            JAVA_HOME_PATH=$JDK_ENTRY
            break
          fi
        fi
      fi
    done
  }

  # search for jdk with designated version code
  _jdk_switch_switch_jdk() {
    local VERSION_CODE JAVA_HOME_PATH EXTRACT_VERSION_CODE
    VERSION_CODE=${1}

    if [[ ! -d $LINUX_JDK_DIR ]] || [[ -z "$(ls -A $LINUX_JDK_DIR)" ]]; then
      _jdk_switch_msg_no_jdk_installed
      return 1
    fi

    # traverse all jdk to select a target jdk
    _jdk_switch_traverse_jdk "$VERSION_CODE"

    # if a target jdk is matched
    if [[ -n $JAVA_HOME_PATH ]]; then
      _jdk_switch_msg_switch_version "$VERSION_CODE"
      _jdk_switch_apply_setting "$VERSION_CODE" "$JAVA_HOME_PATH"
    else
      # show error message if no matched version found
      _jdk_switch_msg_no_target_version "$VERSION_CODE"
      return 1
    fi
  }

  # search installed jdk and apply the first located one as default
  _jdk_switch_search_default() {
    local EXTRACT_VERSION_CODE

    if [[ ! -d $LINUX_JDK_DIR ]] || [[ -z "$(ls -A $LINUX_JDK_DIR)" ]]; then
      _jdk_switch_msg_no_jdk_installed
      return 1
    fi

    # traverse all jdk to select a default jdk
    _jdk_switch_traverse_jdk

    # if a default jdk is selected
    if [[ -n $JAVA_HOME_PATH ]]; then
      _jdk_switch_apply_setting "$EXTRACT_VERSION_CODE" "$JAVA_HOME_PATH" true
    fi

  }
}

alias jdkswitch='jdk-switch'
alias jdkstatus='jdk-status'

_jdk_switch_load_env
_jdk_switch_load_by_os
_jdk_switch_load_config
_jdk_switch_validate_config

unset JDK_SWITCH_SCRIPT_PATH
unset JDK_STATUS_FILE_PATH
unfunction _jdk_switch_load_env
unfunction _jdk_switch_load_by_os
