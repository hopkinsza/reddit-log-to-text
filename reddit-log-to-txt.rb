require "redd"
require "date"

# env.rb gives us:
# redd reddit session credentials
# whether or not to include NSFW results
# which subreddit to log
$Session
$Over_18_and_View_NSFW
$Subreddit
require_relative "env"

################################################
# Set account permissions
#########################
if $Session.username != ''
	print "setting account permissions..."
	if $Over_18_and_View_NSFW
		$Session.edit_preferences(:over_18=>true, :search_include_over_18=>true)
	end
	puts " [done]"
end

################################################
# Function to summarize posts
#############################
# post = Submission in Redd documentation
def summarize_post(post)
	# author
	# [time in seconds]
	# [LocalTime]; UTC [Time]
	# title
	# selftext
	str = post.author.name + "\n"
	# time
	secs = post.created_utc.to_s
	str += secs + "\n"
	date_time = DateTime.strptime(secs, "%s")
	str += Time.at(secs.to_i).to_datetime.to_s + "; UTC " + date_time.to_s
	str += "\n"
	#
	str += post.title + "\n"
	str += post.selftext
	return str
end


################################################
# Load file, populate if empty
##############################
# open file or create if it doesn't exist
file_name = $Subreddit + "-data"
file = File.open(file_name, "a+")

data = file.read
usernames[]
times[]

if data == ""
	print "populating ./#{file_name} with 100 initial entries..."

	$Session.subreddit($Subreddit).search('linux', sort: :new, limit: 1)\
		.each do |submission|
		data += summarize_post(submission)
	end
	puts " [done]"
else
	print "./#{file_name} found, loading data..."
end

puts data

# 
# loop do
# 	# save to file
# 	# sleep for 5 minutes (300 seconds)
# 	sleep 300
# end
# 
# session.subreddit(SUBREDDIT).post_stream do |post|
# end

# $Session.subreddit($Subreddit).search('linux', sort: :new, limit: 1)\
# 	.each do |submission|
# 	puts
# 	puts summarize_post(submission)
# end

# session.subreddit(SUBREDDIT).comments.stream do |comment|
#   if comment.body.include?('roll a dice')
#     comment.reply("It's a #{rand(1..6)}!")
#   elsif comment.body.include?('flip a coin')
#     comment.reply("It's a #{%w(heads tails).sample}!")
#   end
# end
