JDK_SWITCH_SCRIPT_PATH=$( cd `dirname $0` && pwd)
JDK_STATUS_FILE_PATH=$JDK_SWITCH_SCRIPT_PATH/status
JDK_STATUS_FILE="$JDK_STATUS_FILE_PATH/jdk_status"

JDK_SWITCH_MSG_JDK_NOT_FOUND="JDK-SWITCH: JDK home directory not found"
JDK_SWITCH_MSG_NO_JDK_INSTALLED="JDK-SWITCH: No JDK found on this machine"
LATEST_JDK_RELEASE=19

jdkswitch(){
	PARAM=$1
	case $PARAM in
		(-s | --status) jdkstatus ;;
		(-h | --help) _jdk_switch_help_page ;;
		([6-8]) _jdk_switch_search_jdk "1.${1}";;
		([0-9]*) _jdk_switch_search_jdk ${1};;
		(*) echo 'No JDK version matched' ;;
	esac
}

# display jdk status
jdkstatus(){
	if [[ $JDK_STATUS'x' == 'x' ]]; then
		echo "\033[0;31mJDK status UNKNOWN\033[0m"
	else
		echo "Java Home: $JAVA_HOME"
		java -version
	fi
}

# display help page and info
_jdk_switch_help_page(){
	echo "JDK-Switch Zsh Plugin\n"
	echo "usage: jdkswitch -h/--help	Display this page"
	echo "       jdkswitch -s/--status	Display current using version of JDK"
	echo "       jdkswitch <x>      	Switch to JDK version"
}

# load different function based on os type
_jdk_switch_load_by_os(){
	local OSNAME=$(uname -s | tr "[:lower:]" "[:upper:]")
	if [[ $OSNAME == DARWIN* ]]; then
		_jdk_switch_macos_module
	elif [[ $OSNAME == LINUX* ]]; then
		_jdk_switch_linux_module
	else
		echo "Unsupported OS, exiting"
	fi
    unset OSNAME
}

_jdk_switch_error(){
	local MESSAGE=${1}
	echo "\033[0;31m$MESSAGE\033[0m"
}

# save setting to config file and apply setting by reloading shell environment
_jdk_switch_apply_setting(){
	local VERSION_CODE=${1}
	local JAVA_HOME_PATH=${2}
	local INIT_MODE=${3}
	echo "JDK_STATUS=${VERSION_CODE}" > $JDK_STATUS_FILE
	echo "JAVA_HOME=\"${JAVA_HOME_PATH}\"" >> $JDK_STATUS_FILE
	echo "CLASSPATH=.:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar" >> $JDK_STATUS_FILE
	echo "PATH=\$JAVA_HOME/bin:\$PATH" >> $JDK_STATUS_FILE
	if [[ -n $INIT_MODE ]]; then
		echo "JDK-SWITCH: JDK ${VERSION_CODE} found and will be activated.\nReloading shell..." 
	fi
	source ${HOME}/.zshrc && jdkstatus
}

_jdk_switch_macos_module(){
	# search for jdk with designated version code
	_jdk_switch_search_jdk(){
		local VERSION_CODE=${1}
		local JAVA_HOME_PATH=$(/usr/libexec/java_home -v ${VERSION_CODE})
		local INIT_MODE=${2}
		if [[ -d $JAVA_HOME_PATH ]]; then
			_jdk_switch_apply_setting $VERSION_CODE $JAVA_HOME_PATH $INIT_MODE
		else
			# show error message if not in init mode
			[[ ! -n $INIT_MODE ]] && _jdk_switch_error $JDK_SWITCH_MSG_JDK_NOT_FOUND
			return 1
		fi
	}
	# search installed jdk and apply the first located one as default
	_jdk_switch_search_default(){
		for (( i = $LATEST_JDK_RELEASE; i >= 6; i-- )); do
			local VERSION_CODE=1.${i}
			# jdk version code changed after 1.8
			[[ ${i} -gt 8 ]] && VERSION_CODE=${i}			
			# select an installed jdk as the default jdk
			if [[ -d $(/usr/libexec/java_home -v ${VERSION_CODE}) ]]; then
				_jdk_switch_search_jdk $VERSION_CODE true
				[[ $? -eq 0 ]] && break || continue
			elif [[ ${i} == 6 ]]; then
				# i=6 indicate that no installed jdk matched
				_jdk_switch_error $JDK_SWITCH_MSG_NO_JDK_INSTALLED
				return 1
			fi
		done
	}
}

_jdk_switch_linux_module(){
	LINUX_JVM_DIR="/usr/lib/jvm"
	# search for jdk with designated version code
	_jdk_switch_search_jdk(){
		local VERSION_CODE=${1}
		local INIT_MODE=${2}
		local JAVA_HOME_PATH

		for JDK_ENTRY in $LINUX_JVM_DIR/*; do
			if [[ ! -L $JDK_ENTRY ]] && [[ -f "$JDK_ENTRY/bin/java" ]]; then
				# compare version code extract from jdk directory
				ENTRY_VERSION_CODE=$(_jdk_switch_extract_version_code $JDK_ENTRY)
				if [[ $ENTRY_VERSION_CODE == $VERSION_CODE ]]; then
					JAVA_HOME_PATH=$JDK_ENTRY
					break
				fi
			fi
		done

		if [[ -d $JAVA_HOME_PATH ]]; then
			_jdk_switch_apply_setting $VERSION_CODE $JAVA_HOME_PATH $INIT_MODE
		else
			# show error message if not in init mode
			[[ ! -n $INIT_MODE ]] && _jdk_switch_error $JDK_SWITCH_MSG_JDK_NOT_FOUND
			return 1
		fi
	}
	# search installed jdk and apply the first located one as default
	_jdk_switch_search_default(){
		if [[ ! "$(ls -A $LINUX_JVM_DIR)" ]]; then
			_jdk_switch_error $JDK_SWITCH_MSG_NO_JDK_INSTALLED
			return 1
		fi
		for JDK_ENTRY in $LINUX_JVM_DIR/*; do
			if [[ ! -L $JDK_ENTRY ]] && [[ -f "$JDK_ENTRY/bin/java" ]]; then
				VERSION_CODE=$(_jdk_switch_extract_version_code $JDK_ENTRY)
				_jdk_switch_apply_setting $VERSION_CODE $JDK_ENTRY true
				break
			fi
		done
	}
}

_jdk_switch_extract_version_code(){
	local JDK_HOME=${1}
	basename $JDK_HOME | sed 's/jdk-\|java-\|-openjdk-[a-zA-Z0-9_\.\-]*//g'
}


# load saved setting
_jdk_switch_load_setting(){
	if [[ -f $JDK_STATUS_FILE ]]; then
		source $JDK_STATUS_FILE
		export JAVA_HOME=$JAVA_HOME
	else
		[[ ! -d $JDK_STATUS_FILE_PATH ]] && mkdir $JDK_STATUS_FILE_PATH && touch $JDK_STATUS_FILE
	fi
}

# validate saved setting in case of empty or corrupted, in that case search an installed jdk and set as default 
_jdk_switch_validate_setting(){
	if [[ ${JDK_STATUS}'x' == 'x' ]]; then
		_jdk_switch_search_default
		# reload shell environment only if search operation is completed with success, prevent endless reloading
		[[ $? -eq 0 ]] && source ${HOME}/.zshrc
	fi
}

_jdk_switch_load_by_os
_jdk_switch_load_setting
_jdk_switch_validate_setting

unset JDK_SWITCH_SCRIPT_PATH
unset JDK_STATUS_FILE_PATH
