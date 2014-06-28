#dot-files

This is my most committed repository which is both positive and negative. It suggests that I am incredibly OCD, and I don't write enough code (true presently).

### Warning:

This includes my gitconfig and various other user specifics. The installation script is very unforgiving. If you are not me, `cp` the files that fit your fancy.

#Usage

To install execute the following:

```
git clone https://github.com/kirkelifson/dot-files.git
cd dot-files
./install
```

#Required

For maximum pleasure, you must have:

* zshell
* vim `--with-features=big`
* tmux
* gdb
* git (I would hope so)

#Usability

In order for the dynamic prompt to work well with ssh connections and sudo, add this to your sudoers file (always use `visudo`!):

```
Defaults env_keep = "SSH_CONNECTION"
```
