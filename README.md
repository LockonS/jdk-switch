## jdk-switch
A zsh plugin for quickly switching between different jdk versions, and the jdk status won't be restored after reloading the shell.

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
	
	# use 6,7,8 for jdk before jdk9
	$ jdk-switch -v 8
	
	# check activating jdk status
	$ jdk-status
 
	# scan for brew installed jdk and create symbolic links (optional, just a convenient way for IDE to locate JDK)
	$ jdk-switch scan
	```
	
	
#### Notice

1. This plugin works as a tiny tool to help you switch between different jdk versions by writing the jdk version you are currently using to a file and **reloading the shell itself**, so the setting would not be affected if you reload your shell and no additional useless part would show up in `PATH`. And that's also the original purpose of this plugin. 

2. This plugin manages the environment variable like `PATH`, `JAVA_HOME`, so be cautious while changing these variables in your `~/.zshrc` or anywhere else, especially when adding settings about configuring the java environment which has something to do with any of these variables, as the plugin setting might be overridden by your own setting.
