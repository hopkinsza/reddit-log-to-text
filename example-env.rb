# bot session credentials
$Session = Redd.it(
	user_agent: 'Redd:reddit-log-to-txt:v0.0.0',
	client_id:  '',
	secret:     '',
	# an account is necessary to view nsfw posts
	# or use the $Post_Downtime feature below.
	# remove the "#" from these lines and add your
	# credentials to add an account.
	# username:   '',
	# password:   ''
)

# this will change settings on the account you give the bot
# specifically, :over_18=>true :search_include_over_18=>true
#
# If this is not set to true, the bot will not be able to
# view nsfw posts
$Over_18_and_View_NSFW = false

# r/$Subreddit
# the subreddit you want to log, *without* the 'r/' prefix
$Subreddit = ''

# If a user posts twice within this number of seconds, their
# post will be deleted.
# A value of 0 means this feature is not used.
#
# Obviously, the bot must be an admin in the subreddit to do this.
$Post_Downtime = 0
