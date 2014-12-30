#dot-files

#Warning:

###The installation script is very unforgiving. If you are not me it's wise to inspect the contents and take what you like.

#Usage:

To install execute the following:

```
git clone https://github.com/kirkelifson/dot-files.git
cd dot-files
./install
```

#Required:

For maximum pleasure, you must have:

* zsh
* vim `--with-features=big`
* tmux
* gdb
* git (I would hope so)

#Usability:

In order for the dynamic prompt to work well with ssh connections and sudo, add this to your sudoers file (always use `visudo`!):

```
Defaults env_keep = "SSH_CONNECTION"
```
