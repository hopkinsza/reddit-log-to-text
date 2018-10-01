require "redd"

# env.rb gives us:
# redd reddit session credentials
$Session
# whether or not to include NSFW results
$Over_18_and_View_NSFW
# which subreddit to log
$Subreddit
require_relative "env"

# post = Submission in Redd documentation
def summarize_post(post)
	str = ''
	str += post.author.to_s
	str += "\n"
	str += post.created_utc.to_s
	str += "\n"
	str += post.title
	str += "\n"
	str += post.selftext
	return str
	# str = post.inspect
end

$Session.subreddit($Subreddit).search('linux', sort: :new, limit: 1)\
	.each do |submission|
	puts
	puts summarize_post(submission)
end

# file = File.open($Subreddit << '-data', "rw")
# data = file.read
# if data == ""
# 	puts "populating data file with 100 initial entries..."
# 	# TODO continue
# end
# 
# if $Over_18_and_View_NSFW
# 	$Session.edit_preferences(:over_18=>true, :search_include_over_18=>true)
# end
# 
# loop do
# 
# 	# sleep for 5 minutes (300 seconds)
# 	sleep 300
# end
# puts "5 newest posts from r/" << $Subreddit
# 

# session.subreddit(SUBREDDIT).post_stream do |post|
# end

# session.subreddit(SUBREDDIT).comments.stream do |comment|
#   if comment.body.include?('roll a dice')
#     comment.reply("It's a #{rand(1..6)}!")
#   elsif comment.body.include?('flip a coin')
#     comment.reply("It's a #{%w(heads tails).sample}!")
#   end
# end
