# reddit-log-to-txt
Simple script to log reddit posts using the *Redd* API for Ruby.


**Prerequisites**:

`[package manager] install ruby`

use `git clone` to pull down this repository

(inside the project directory) install dependencies:

`gem install --user-install bundler && bundle install`

or install them manually:

`gem install --user-install redd`

**Instructions**:

Modify `example-env.rb` and save as `env.rb`

Run `ruby reddit-log-to-txt.rb` to to start the script and log new posts on the given subreddit every 5 minutes.

Data is saved in text files named "$Subreddit\-data".
