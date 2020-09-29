#!/bin/sh
JDK_SWITCH_SCRIPT_PATH=$( cd `dirname $0` && pwd)
STATUS_FILE_PATH=$JDK_SWITCH_SCRIPT_PATH/status
JDK_STATUS_FILE="$STATUS_FILE_PATH/jdk_status"

alias java_list='/usr/libexec/java_home -V'

if [[ -f $JDK_STATUS_FILE ]]; then
	source $JDK_STATUS_FILE
	export JAVA_HOME=$JAVA_HOME
else
	if [[ ! -d $STATUS_FILE_PATH ]]; then
		mkdir $STATUS_FILE_PATH
	fi
	touch $JDK_STATUS_FILE
fi

function jdkswitch(){
	PARAM=$1
	case $PARAM in
		(s | status) jdkstatus ;;
		(h | help) _jdk_switch_help_page ;;
		(6 | 7 | 8) _save_jdk_setting "1.${1}";;
		([0-9]*) _save_jdk_setting ${1};;
		(*) echo 'No JDK version matched' ;;
	esac
}

# display jdk status
function jdkstatus(){
	if [[ $JDK_STATUS'x' == 'x' ]]; then
		echo "\033[0;31mJDK status UNKNOWN\033[0m"
	else
		javac -version
		java -version
	fi
}

# display help page and info
function _jdk_switch_help_page(){
	echo "JDK version switch tool -- OSX Version"
	echo "h/help 		Display this page"
	echo "s/status  	Display current using version of JDK"
	echo ""
	echo "------Usage------"
	echo "JDK 1.6-1.8	Use \`jdkswitch 1.x\` or \`jdkswitch x\` \nJDK 9+	Use \`jdkswitch x\`"
}

# export jdk setting to file
function _save_jdk_setting(){
	local VERSION_CODE=${1}
	local JAVA_HOME_PATH=$(/usr/libexec/java_home -v ${VERSION_CODE})
	if [[ -d $JAVA_HOME_PATH ]]; then
		echo "JDK_STATUS=${VERSION_CODE}" > $JDK_STATUS_FILE
		if [[ -d $JAVA_HOME_PATH ]]; then
			echo "JAVA_HOME=${JAVA_HOME_PATH}" >> $JDK_STATUS_FILE
			echo "CLASSPATH=.:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar" >> $JDK_STATUS_FILE
			echo "PATH=\$JAVA_HOME/bin:\$PATH" >> $JDK_STATUS_FILE
		fi
		unset JAVA_HOME_PATH
		source ${HOME}/.zshrc && java -version
	else
		echo "\033[0;31mJDK home directory not found\033[0m"
	fi

}

# check installed jdk while current jdk status is unknown
function _search_installed_jdk(){
	for (( i = 10; i >= 6; i-- )); do

		local VERSION_CODE=1.${i}
		# jdk 9 and 10 require different format version code
		if [[ ${i} -gt 8 ]]; then
			VERSION_CODE=${i}
		fi

		# select an installed jdk as the default jdk
		if [[ -d $(/usr/libexec/java_home -v ${VERSION_CODE}) ]]; then
			_save_jdk_setting $VERSION_CODE
			echo "JDK-SWITCH: JDK ${VERSION_CODE} found and will be applied as activating jdk."
			echo "Reloading shell..."
			break
		elif [[ ${i} == 6 ]]; then
			# i=6 indicate that no installed jdk matched
			echo "JDK-SWITCH: It seems that this machine haven't installed any jdk yet."
			return 1
		fi
	done
}

# applying jdk setting during shell initialization
function _apply_jdk_setting(){
	if [[ ${JDK_STATUS}'x' == 'x' ]]; then
		_search_installed_jdk
		source ${HOME}/.zshrc
	fi
}

_apply_jdk_setting

unset JDK_SWITCH_SCRIPT_PATH
unset STATUS_FILE_PATH
