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
		echo "${Red}JDK status UNKNOWN${NC}"
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
		echo "${Red}JDK home directory not found${NC}"
	fi
}
# applying jdk setting during shell initialization
function _apply_jdk_setting(){
	local JAVA_HOME_PATH=$(/usr/libexec/java_home -v ${JDK_STATUS})
	if [[ -d $JAVA_HOME_PATH ]]; then
		export JAVA_HOME=${JAVA_HOME_PATH}
		export CLASSPATH=${CLASSPATH}:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar
		export PATH=$JAVA_HOME/bin:$PATH
	fi
}

_apply_jdk_setting

unset JDK_SWITCH_SCRIPT_PATH


# export JAVA_6_HOME=$(/usr/libexec/java_home -v 1.6)
# export JAVA_7_HOME=$(/usr/libexec/java_home -v 1.7)
# export JAVA_8_HOME=$(/usr/libexec/java_home -v 1.8)
# export JAVA_HOME=$JAVA_8_HOME
# export CLASSPATH=${CLASSPATH}:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:/Users/LockonStratos/CodeSketch/Library/crossroad-core
# export PATH=$JAVA_HOME/bin:$PATH
# function jdk6 {
# 	export JAVA_HOME=$JAVA_6_HOME
# 	export CLASSPATH=${CLASSPATH}:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar
# 	export PATH=$JAVA_HOME/bin:$PATH
# }
# function jdk7 {
# 	export JAVA_HOME=$JAVA_7_HOME
# 	export CLASSPATH=${CLASSPATH}:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar
# 	export PATH=$JAVA_HOME/bin:$PATH
# }
# function jdk8 {
# 	export JAVA_HOME=$JAVA_8_HOME
# 	export CLASSPATH=${CLASSPATH}:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar
# 	export PATH=$JAVA_HOME/bin:$PATH
# }