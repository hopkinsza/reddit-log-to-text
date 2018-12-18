# reddit-log-to-txt
Simple script to log reddit posts using the *Redd* API for Ruby.

---

## Prerequisites

**install ruby and git, pull this repo**

`[package manager] install ruby git`

use `git clone` to pull down this repository

**install redd**

`cd ~/reddit-log-to-text`

`gem install --user-install redd`

this will give a warning about some path like `/home/$USER/.gem/ruby/$VERSION/bin` not being in your PATH; add it permanently with the following steps:

- copy the path from the warning (using ctrl+shift+c)
- run `echo "export PATH=$PATH:/the/path/you/copied" >> ~/.bashrc` (paste using ctrl+shift+v)
- run `source ~/.bashrc`

---

## Usage Instructions

Modify `example-env.rb` and save as `env.rb`

Run `ruby reddit-log-to-txt.rb` to to start the script and log new posts on the given subreddit every 5 minutes.

Data is saved in text files named "$Subreddit\-data".
