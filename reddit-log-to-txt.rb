require "redd"
require "date"

# env.rb gives us:
# redd reddit session credentials
# whether or not to include NSFW results
# which subreddit to log
# how close in time 2 posts from same user can be
$Session
$Over_18_and_View_NSFW
$Subreddit
$Post_Downtime
print "connecting to reddit..."
require_relative "env"
puts " [done]"

# RedditLog.rb defines a class,
# RedditLog, that abstracts away
# most of the shenanigans to make this
# main file much more readable
require_relative "RedditLog"

################################################
# Set account permissions
#########################
print "logged in as "
begin
	# this will crash if not logged in
	puts $Session.me.name
	if $Over_18_and_View_NSFW
		print "setting account permissions..."
		$Session.edit_preferences(:over_18=>true,
								  :search_include_over_18=>true)
		puts " [done]"
	end
rescue
	puts "anonymous"
end

################################################
# Load file, populate if empty
##############################
reddit_log = RedditLog.new($Subreddit)

################################################
# Delete logged posts if they violate
# $Post_Downtime.
# Load posts every 3 minutes log them.
######################################
#
# repeats every 5 minutes, infinitely
# (until stopped with ^C)
loop do
	reddit_log.check_violations
	reddit_log.fetch_new_posts
	sleep 300
end
