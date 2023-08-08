## jdk-switch
A zsh plugin for quickly switching between different jdk versions, and the jdk status won't be restored after reloading the shell. **Now with support for Linux**. 

### Install

1. Clone this repository in oh-my-zsh's plugins directory
	
	```shell
	$ git clone https://github.com/LockonS/jdk-switch.git $ZSH/custom/plugins/jdk-switch
	```
	
2. Enable the plugin by adding `jdk-switch` in `plugins` in your `~/.zshrc`

    > If you have some extra settings about `PATH` variable, you may need to add `jdk-switch-enable `in `~/.zshrc` to ensure `JAVA_HOME` was included in `PATH`.
         
	```shell
	plugins=( [plugins...] jdk-switch)
	```
	
3. Usage
	
	```shell
	# use jdk-switch to switch between different jdk versions
	# switch to jdk 11
	$ jdk-switch -v 11
	# or (legacy support)
	$ jdk-switch 11
	
	# check activating jdk status
	$ jdk-status
	```
	
	
#### Notice

1. This plugin works as a tiny tool to help you switch between different jdk versions by writing the jdk version you are currently using to a file and **reloading the shell itself**, so the setting would not be affected if you reload your shell and no additional useless part would show up in `PATH`. And that's also the the sole purpose of developing this plugin. 

2. This plugin manages the environment variable like `PATH`, `JAVA_HOME` and `CLASS_PATH`, so be cautious while changing these variables in your `~/.zshrc` or anywhere else, especially when adding settings about configuring the java environment which has something to do with any of these variables, as the plugin setting might be overridden by your own setting.
	
#### Known issues

1. There is a flaw while running `/usr/libexec/java_home -v <version>` on MacOS to get `JAVA_HOME`, as this tool will return inaccurate result in some cases. For example, on a machine installed with JDK 11 and JDK 17, `/usr/libexec/java_home -v 12` will return the directory of JDK 17. As this plugin rely on `/usr/libexec/java_home`, execute `jdk-switch 12` will switch to JDK 17 instead rather than give an error. 
	
