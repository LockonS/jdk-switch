## jdk-switch
A zsh plugin for quickly switch between different jdk versions, and the jdk status won't be restored after reload the shell.

### Usage

#### Step 1
- Download this plugin and place it in `path-to-zsh/custom/plugins` 

#### Step 2
- Activate the plugin by adding `jdk-switch`in `plugins` in your config file

#### Step 3
- Setup hostfiles

	1. This plugin works as a tiny tool to help you switch between different jdk versions by export the current using jdk version to a file and reload the shell itself, so the setting would not be affected if you reload your shell and no additional useless part would show up in `$PATH`. And that's also the my sole purpose to develop this tool.

	2. Since this plugin manage the environment variable like `$PATH`, `$JAVA_HOME` and `$CLASS_PATH`, be cautious while changing these variables in your shell init script, especially when adding some addition settings about configure the java environment, cause your custom setting may override the plugin setting on these three variables.
	
	3. Use `jdkstatus` to check which host script is being used currently.
