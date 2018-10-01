# bot session credentials
print "connecting to reddit..."
$Session = Redd.it(
	user_agent: 'Redd:reddit-log-to-txt:v0.0.0',
	client_id:  '',
	secret:     '',
	# an account is necessary to view nsfw posts
	# username:   '',
	# password:   ''
)
puts " [done]"

# this will change settings on the account you give the bot
# specifically, :over_18=>true :search_include_over_18=>true
$Over_18_and_View_NSFW = false

# r/$Subreddit
$Subreddit = ''
