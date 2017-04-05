## jdk-switch
A zsh plugin for quickly switch between different jdk versions, and the jdk status won't be restored after reload the shell. **Please notice currently this plugin only works on mac**. 

### Install

1. Clone this repository in oh-my-zsh's plugins directory
	
	```sh
	git clone https://github.com/LockonS/jdk-switch.git $ZSH/custom/plugins/jdk-switch
	```
	
2. Enable the plugin by adding `jdk-switch` in `plugins` in your `~/.zshrc`

	```sh
	plugins=( [plugins...] jdk-switch)
	```
	
3. Usage
	
	```sh
	# use jdkswitch to switch between different jdk versions
	# switch to jdk 8
	$ jdkswitch 1.8
	# or
	$ jdkswitch 8
	
	# check activating jdk
	$ jdkstatus
	```
	
	
#### Notice

1. This plugin works as a tiny tool to help you switch between different jdk versions by export the current using jdk version to a file and **reload the shell itself**, so the setting would not be affected if you reload your shell and no additional useless part would show up in `PATH`. And that's also the the sole purpose to develop this plugin. 

2. Since this plugin manage the environment variable like `PATH`, `$JAVA_HOME` and `$CLASS_PATH`, be cautious while changing these variables in your `~/.zshrc` or anywhere else, especially when adding some addition settings about configuring the java environment which has something to do with all these variables, as the plugin setting might be overrided by your own setting.
	
	
