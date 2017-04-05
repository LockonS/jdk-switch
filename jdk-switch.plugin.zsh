#!/bin/sh
JDK_SWITCH_SCRIPT_PATH=$( cd `dirname $0` && pwd)
STATUS_FILE_PATH=$JDK_SWITCH_SCRIPT_PATH/status
JDK_STATUS_FILE="$STATUS_FILE_PATH/jdk_status"

# configure the minimun and the maximum jdk version
MINIUM_JDK_VERSION=6
MAXIMUM_JDK_VERSION=8

alias java_list='/usr/libexec/java_home -V'

if [[ -f $JDK_STATUS_FILE ]]; then
	source $JDK_STATUS_FILE
else
	if [[ ! -d $STATUS_FILE_PATH ]]; then
		mkdir $STATUS_FILE_PATH
	fi
	touch $JDK_STATUS_FILE
fi

function jdkswitch(){
	if [[ ${1} =~ ^[${MINIUM_JDK_VERSION}-${MAXIMUM_JDK_VERSION}]$ ]]; then
		_save_jdk_setting "1.${1}"
	elif [[ ${1} =~ ^1.[${MINIUM_JDK_VERSION}-${MAXIMUM_JDK_VERSION}]$ ]]; then
		_save_jdk_setting ${1}
	else
		echo 'No JDK version matched'
	fi
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

# export jdk setting to file
function _save_jdk_setting(){
	local VERSION_CODE=${1}
	local JAVA_HOME_PATH=$(/usr/libexec/java_home -v ${1})
	if [[ -d $JAVA_HOME_PATH ]]; then
		echo "JDK_STATUS=${VERSION_CODE}" > $JDK_STATUS_FILE
		source ${HOME}/.zshrc
	else
		echo "\033[0;31mJDK home directory not found\033[0m"
	fi
}

# check installed jdk while current jdk status is unknown
function _locate_installed_jdk(){
	# for now only jdk 6,7 and 8 is mainly used
	for (( i = ${MAXIMUM_JDK_VERSION}; i >= ${MINIUM_JDK_VERSION}; i-- )); do
		local VERSION_CODE=1.${i}
		# select an installed jdk as the default jdk
		if [[ -d $(/usr/libexec/java_home -v ${VERSION_CODE}) ]]; then
			_save_jdk_setting $VERSION_CODE
			echo "JDK-SWITCH: JDK ${VERSION_CODE} found and will be applied as activating jdk."
			echo "Reloading shell..."
			break
		elif [[ ${i} == ${MINIUM_JDK_VERSION} ]]; then
			# i=6 indicate that no installed jdk matched
			echo "JDK-SWITCH: It seems that this machine haven't installed any jdk yet."
			return 1
		fi
	done
}

# applying jdk setting during shell initialization
function _apply_jdk_setting(){
	if [[ ${JDK_STATUS}'x' == 'x' ]]; then
		_locate_installed_jdk
		source ${HOME}/.zshrc
	else
		local JAVA_HOME_PATH=$(/usr/libexec/java_home -v ${JDK_STATUS})
		if [[ -d $JAVA_HOME_PATH ]]; then
			export JAVA_HOME=${JAVA_HOME_PATH}
			export CLASSPATH=${CLASSPATH}:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar
			export PATH=$JAVA_HOME/bin:$PATH
		fi
	fi
}

_apply_jdk_setting

unset JDK_SWITCH_SCRIPT_PATH
