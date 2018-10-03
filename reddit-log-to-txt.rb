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
# Function to summarize posts, and one for
# formatted date/time
#####################
# puts local and utc time based on
# seconds since epoch
def local_and_utc(secs)
	return Time.at(secs).to_datetime.to_s + "; UTC " + DateTime.strptime(secs.to_s, "%s").to_s
end

# post = Submission in Redd documentation
def summarize_post(post)
	# author
	# [time in seconds]
	# id
	# [LocalTime]; UTC [Time]
	# title
	# selftext on one line
	str = post.author.name + "\n"
	secs = post.created_utc.to_i
	str += secs.to_s + "\n"
	# str += post.id + "\n"
	str += local_and_utc(secs) + "\n"
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
# Load posts every 3 minutes, log them,
# delete if they violate $Post_Downtime
#######################################
def log_to_top_of_file(text)
	File.open("temp", "w") do |temp|
		temp.write(text)
		temp.write(File.read(File_Name))
		File.delete(File_Name)
		File.rename("temp", File_Name)
	end
end
# def log_post(post)
# 	# log post at top of file
# 	File.open("temp", "w") do |temp|
# 		temp.write(summarize_post(post))
# 		temp.write(File.read(File_Name))
# 		File.delete(File_Name)
# 		File.rename("temp", File_Name)
# 	end
# end
def remove_post_and_pm(post)
	# TODO REMEMBER TO UNCOMMENT THIS FOR PRODUCTION
	# post.author.send_message(subject: ("r/" + $Subreddit + " post has been removed"),
	# 						 text: "Your post, \"#{post.title}\", has been removed
	# 						 for being posted within #{$Post_Downtime} seconds
	# 						 of your last submission.",
	# 						 from: nil)
	# post.remove(spam: false)
end
def get_names_and_times_in_downtime(data_arr)
	data_arr = data.split("\n")
	names = []
	times = []
	for i in 0..data_arr.length
		if i % 6 == 0
			names.push data_arr[i]
		elsif i % 6 == 1
			times.push data_arr[i].to_i
			break if post_time - pushme >= $Post_Downtime
		end
	end

	return names, times
end

# repeats every 5 minites, infinitely
loop do
	sleep 300
	data = load_data
	data_arr = data.split("\n")

	# get posts since latest logged post
	latest_name = data_arr[0]
	latest_time = data_arr[1]

	$Session.subreddit($Subreddit).search('*', sort: :new, limit: 1)\
		.reverse_each do |post|

	end

	if $Post_Downtime >= 0
		names_in_downtime = get_names_in_downtime(data_arr)
		times_in_downtime = get_times_in_downtime(data_arr)
	end
end

$Session.subreddit($Subreddit).post_stream do |post|
	puts "post submitted at #{local_and_utc(post.created_utc.to_i)}!"

	print "logging..."
	log_post(post)
	puts " [done]"

	if $Post_Downtime >= 0
		print "checking if it violated $Post_Downtime..."

		post_name = post.author.name
		post_time = post.created_utc.to_i
		# gather time, name info on posts from last $Post_Downtime seconds
		data_arr = data.split("\n")
		times = []
		names = []
		for i in 0..data_arr.length
			if i % 6 == 0
				pushme = data_arr[i]
				names.push pushme
			elsif i % 6 == 1
				pushme = data_arr[i].to_i
				times.push pushme
				break if post_time - pushme >= $Post_Downtime
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
			puts "by #{name}"
		else
			puts " [nope]"
		end
		puts
		data = load_data
	end
end

# $Session.subreddit($Subreddit).search('linux', sort: :new, limit: 1)\
# 	.each do |submission|
# 	puts
# 	puts summarize_post(submission)
# end
