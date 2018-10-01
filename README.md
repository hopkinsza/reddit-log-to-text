# reddit-log-to-txt
Simple script to log reddit posts using the *Redd* API for Ruby.


__Prerequisites__:

`[package manager] install ruby`

`gem install redd` or `gem install bundler && bundle install`


__Instructions__:

Modify `example-env.rb` and save as `env.rb`
Run `ruby reddit-log-to-txt.rb` to to start the script and log new posts on the given subreddit every 5 minutes.

Data is saved in text files named "$Subreddit\-data".
