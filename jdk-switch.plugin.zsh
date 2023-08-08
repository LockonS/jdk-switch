# shellcheck disable=SC1090,SC2164
JDK_SWITCH_SCRIPT_PATH=$(
  cd "$(dirname "$0")"
  pwd
)

_jdk_switch_load_env() {
  LATEST_JDK_RELEASE=20
  JDK_STATUS_FILE_PATH=$JDK_SWITCH_SCRIPT_PATH/status
  JDK_STATUS_FILE=$JDK_STATUS_FILE_PATH/jdk_status

  Red='\033[0;31m'
  Green='\033[0;32m'
  Yellow='\033[0;33m'
  Blue='\033[1;34m'
  NC='\033[0m'

  JSMSG_JDK_NOT_FOUND="${Red}JDK-SWITCH: JDK home directory not found${NC}"
  JSMSG_NO_JDK_INSTALLED="${Red}JDK-SWITCH: No JDK found on this machine${NC}"
  JSMSG_JDK_STATUS_UNKNOWN="${Red}JDK-SWITCH: JDK status unknown${NC}"
  JSMSG_NO_JDK_MATCHED="${Red}JDK-SWITCH: No JDK version matched${NC}"
}

jdk-switch() {
  local PARAM=$1
  case $PARAM in
    -s | --status) jdk-status ;;
    -h | --help) _jdk_switch_help_page ;;
    [6-8]) _jdk_switch_switch_jdk "1.${1}" ;;
    [0-9]*) _jdk_switch_switch_jdk "${1}" ;;
    *) echo -e "$JSMSG_NO_JDK_MATCHED" && return 1 ;;
  esac
}

jdk-switch-enable() {
  export PATH=$JAVA_HOME/bin:$PATH
}

# display jdk status
jdk-status() {
  if [[ -z $JDK_STATUS ]]; then
    echo -e "$JSMSG_JDK_STATUS_UNKNOWN"
  else
    echo "JAVA_HOME: $JAVA_HOME"
    java -version
  fi
}

# display help page and info
_jdk_switch_help_page() {
  echo -e "JDK-Switch Zsh Plugin\n"
  echo "usage: jdk-switch -h/--help	Display this page"
  echo "       jdk-switch -s/--status	Display current using version of JDK"
  echo "       jdk-switch <x>      	Switch to JDK version"
}

# load different function based on os type
_jdk_switch_load_by_os() {
  local OSNAME
  OSNAME=$(uname -s | tr "[:lower:]" "[:upper:]")
  if [[ $OSNAME == DARWIN* ]]; then
    _jdk_switch_macos_module
  elif [[ $OSNAME == LINUX* ]]; then
    _jdk_switch_linux_module
  else
    echo "Unsupported OS, exiting"
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
    echo "CLASSPATH=.:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar"
    echo "PATH=\$JAVA_HOME/bin:\$PATH"
  } >>"$JDK_STATUS_FILE"

  # print remind message if jdk was found and activated
  [[ -n $INIT_MODE ]] && echo -e "JDK-SWITCH: Activate jdk ${Blue}${VERSION_CODE}${NC} as default jdk.\nReloading shell..."

  # print jdk version and reload shell
  "$JAVA_HOME_PATH/bin/java" -version
  exec zsh
}

# load saved setting
_jdk_switch_load_config() {
  # create status file and directory if not exist
  [[ ! -d "$JDK_STATUS_FILE_PATH" ]] && mkdir "$JDK_STATUS_FILE_PATH"
  [[ ! -f "$JDK_STATUS_FILE" ]] && touch "$JDK_STATUS_FILE"

  # apply environment variable in JDK_STATUS_FILE
  source "$JDK_STATUS_FILE" && export JAVA_HOME

  # in case jdk was upgraded by other applications, e.g. homebrew
  [[ ! -d $JAVA_HOME ]] && unset JDK_STATUS
}

# validate saved setting in case of empty or corrupted, in that case search an installed jdk and set as default
_jdk_switch_validate_config() {
  [[ -n $JDK_STATUS ]] && return 0

  # reload environment only if search operation complete with success
  if _jdk_switch_search_default; then
    exec zsh
  fi
}

_jdk_switch_macos_module() {
  MACOS_JVM_DIR=/Library/Java/JavaVirtualMachines
  BREW_JVM_DIR=/opt/homebrew/opt

  # search for jdk with designated version code
  _jdk_switch_switch_jdk() {
    local VERSION_CODE JAVA_HOME_PATH INIT_MODE
    VERSION_CODE=${1}
    JAVA_HOME_PATH=$(/usr/libexec/java_home -v "$VERSION_CODE")
    INIT_MODE=${2}
    if [[ -d $JAVA_HOME_PATH ]]; then
      _jdk_switch_apply_setting "$VERSION_CODE" "$JAVA_HOME_PATH" "$INIT_MODE"
    else
      # show error message if not in init mode
      [[ -z $INIT_MODE ]] && echo -e "$JSMSG_JDK_NOT_FOUND"
      return 1
    fi
  }

  # search installed jdk and apply the first located one as default
  _jdk_switch_search_default() {
    local VERSION_CODE
    for ((i = LATEST_JDK_RELEASE; i >= 6; i--)); do
      VERSION_CODE=1.${i}
      # jdk version code changed after 1.8
      [[ ${i} -gt 8 ]] && VERSION_CODE=${i}
      # select an installed jdk as the default jdk
      if [[ -d $(/usr/libexec/java_home -v "$VERSION_CODE") ]]; then
        _jdk_switch_switch_jdk "$VERSION_CODE" true
        [[ $? -eq 0 ]] && break || continue
      elif [[ ${i} == 6 ]]; then
        # i=6 indicate that no installed jdk matched
        echo -e "$JSMSG_NO_JDK_INSTALLED"
        return 1
      fi
    done
  }
}

_jdk_switch_linux_module() {
  LINUX_JVM_DIR="/usr/lib/jvm"

  # extract version code from jdk home directory
  _jdk_switch_extract_version_code() {
    basename "${1}" | sed 's/jdk-\|java-\|-openjdk-[a-zA-Z0-9_\.\-]*//g'
  }

  # search for jdk with designated version code
  _jdk_switch_switch_jdk() {
    local VERSION_CODE INIT_MODE JAVA_HOME_PATH ENTRY_VERSION_CODE
    VERSION_CODE=${1}
    INIT_MODE=${2}

    if [[ ! "$(ls -A $LINUX_JVM_DIR)" ]]; then
      echo -e "$JSMSG_NO_JDK_INSTALLED"
      return 1
    fi

    for JDK_ENTRY in "$LINUX_JVM_DIR"/*; do
      if [[ ! -L $JDK_ENTRY ]] && [[ -f "$JDK_ENTRY/bin/java" ]]; then
        # compare version code extract from jdk directory
        ENTRY_VERSION_CODE=$(_jdk_switch_extract_version_code "$JDK_ENTRY")
        if [[ $ENTRY_VERSION_CODE == "$VERSION_CODE" ]]; then
          JAVA_HOME_PATH=$JDK_ENTRY
          break
        fi
      fi
    done

    if [[ -d $JAVA_HOME_PATH ]]; then
      _jdk_switch_apply_setting "$VERSION_CODE" "$JAVA_HOME_PATH" "$INIT_MODE"
    else
      # show error message if not in init mode
      [[ -z $INIT_MODE ]] && echo -e "$JSMSG_JDK_NOT_FOUND"
      return 1
    fi
  }

  # search installed jdk and apply the first located one as default
  _jdk_switch_search_default() {
    if [[ ! -d $LINUX_JVM_DIR ]]; then
      echo -e "$JSMSG_NO_JDK_INSTALLED"
      return 1
    fi
    if [[ ! "$(ls -A $LINUX_JVM_DIR)" ]]; then
      echo -e "$JSMSG_NO_JDK_INSTALLED"
      return 1
    fi

    for JDK_ENTRY in "$LINUX_JVM_DIR"/*; do
      if [[ ! -L $JDK_ENTRY ]] && [[ -f "$JDK_ENTRY/bin/java" ]]; then
        VERSION_CODE=$(_jdk_switch_extract_version_code "$JDK_ENTRY")
        _jdk_switch_apply_setting "$VERSION_CODE" "$JDK_ENTRY" true
        break
      fi
    done
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
