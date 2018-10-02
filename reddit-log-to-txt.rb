require "redd"
require "date"

# env.rb gives us:
# redd reddit session credentials
# whether or not to include NSFW results
# which subreddit to log
# how close 2 posts from same user can be
$Session
$Over_18_and_View_NSFW
$Subreddit
$Post_Downtime
print "connecting to reddit..."
require_relative "env"
puts " [done]"

################################################
# Set account permissions
#########################
print "logged in as "
begin
	puts $Session.me.name
	if $Over_18_and_View_NSFW
		print "setting account permissions..."
		$Session.edit_preferences(:over_18=>true, :search_include_over_18=>true)
		puts " [done]"
	end
rescue
	puts "anonymous"
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
	str += post.selftext.gsub(/\n/, "")
	str += "\n\n"
	return str
end


################################################
# Load file, populate if empty
##############################
# open file or create if it doesn't exist
File_Name = $Subreddit + "-data"
def load_data
	return File.open(File_Name, "a+").read
end
data = load_data

if data == ""
	print "populating ./#{File_Name} with 100 initial entries..."

	$Session.subreddit($Subreddit).search("*", sort: :new, limit: 100)\
		.each do |submission|
		data += summarize_post(submission)
	end
	File.write(File_Name, data)
	puts " [done]"
else
	puts "./#{File_Name} found"
end

################################################
# Stream posts. Log to file as they come in,
# delete if they violate $Post_Downtime
#######################################

def remove_post_and_pm(post)
	# TODO REMEMBER TO UNCOMMENT THIS FOR PRODUCTION
	# post.author.send_message(subject: ("r/" + $Subreddit + " post has been removed"),
	# 						 text: "Your post, \"#{post.title}\", has been removed
	# 						 for being posted within #{$Post_Downtime} seconds
	# 						 of your last submission.",
	# 						 from: nil)
	# post.remove(spam: false)
end

def log_post(post)
	# log post at beginning of file
	File.open("temp", "w") do |temp|
		temp.write(summarize_post(post))
		temp.write(File.read(File_Name))
		File.delete(File_Name)
		File.rename("temp", File_Name)
	end
end

$Session.subreddit($Subreddit).post_stream do |post|
	puts "post submitted at #{post.created_utc.to_s}!"

	print "logging..."
	log_post(post)
	puts " [done]"

	if $Post_Downtime >= 0
		print "checking if it violated $Post_Downtime..."

		# gather time, name info on posts from last $Post_Downtime seconds
		data = load_data
		data_arr = data.split("\n")
		times = []
		names = []
		for i in 0..data_arr.length
			if i % 6 == 0
				names.push data_arr[i]
			elsif i % 6 == 1
				times.push data_arr[i]
				break if post.created_utc.to_i - times[i] >= $Post_Downtime
			end
		end

		name = post.author.name
		violated = false
		names.each do |n|
			if n ==  name
				violated = true
				break
			end
		end
		if violated
			remove_post_and_pm(post)
			puts " [GOTCHA!!!]"
			puts "rekt post: #{post.title}"
		else
			puts "[nope]"
		end
	end
end

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
