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
	# this will crash if not logged in
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
	str += post.id + "\n"
	str += local_and_utc(secs) + "\n"
	str += post.title + "\n"
	str += post.selftext.gsub(/\n/, "")
	str += "\n\n"
	return str
end

################################################
# Load file, populate if empty
##############################
# open file or create & populate if it doesn't exist
File_Name = $Subreddit + "-data"

if File.exist?(File_Name)
	puts "./#{File_Name} found"
else
	print "populating ./#{File_Name} with 100 initial entries..."
	str = ""
	$Session.subreddit($Subreddit).search("*", sort: :new, limit: 100)\
		.each do |submission|
		str += summarize_post(submission)
	end
	File.open(File_Name, "a") do |f|
		f.write(str)
	end
	puts " [done]"
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
def remove_post_and_pm(post)
	# TODO REMEMBER TO UNCOMMENT THIS FOR PRODUCTION
	# post.author.send_message(subject: ("r/" + $Subreddit + " post has been removed"),
	# 						 text: "Your post, \"#{post.title}\", has been removed
	# 						 for being posted within #{$Post_Downtime} seconds
	# 						 of your last submission.",
	# 						 from: nil)
	# post.remove(spam: false)
end
def get_names_in_downtime(data_arr)
	#TODO wtf is going on here
	names = []
	for i in 0..data_arr.length
		if i % 7 == 0
			names.push data_arr[i]
		elsif i % 7 == 1
			time = data_arr[i].to_i
			break if post_time - time >= $Post_Downtime
		end
	end

	return names
end

# repeats every 5 minites, infinitely
print "fetching posts..."
loop do
	data_arr = File.read(File_Name).split("\n")

	# data of latest logged post
	latest_name = data_arr[0]
	latest_time = data_arr[1]
	latest_id   = data_arr[2]

	# violating posts *within this post grab* will be
	# removed, if $Post_Downtime is set. Otherwise, this
	# variable is not used.
	unique_names = []
	unique_times = []
	# get posts since latest logged post, oldest first
	$Session.subreddit($Subreddit).search('all', sort: :new, after: latest_id)\
		.reverse_each do |post|
		log_to_top_of_file(summarize_post(post))

		# TODO redo this completely in a smarter way. we will log the files first,
		# then check the FILE for $Post_Downtime violations.
		# if $Post_Downtime >= 0
		# 	post_name = post.author.name
		# 	#TODO check $Post_Downtime violation
		# 	# check against posts from this post grab
		# 	unique = true
		# 	for i in 0..unique_names.length
		# 		if post_name == unique_names[i]
		# 			unique = false
		# 		end
		# 	end
		# 	if unique
		# 		if post
		# 		unique_names.push post_name
		# 		unique_times.push post.created_utc.to_i
		# 	end

		# 	#TODO
		# 	# check against already logged posts
		# 	names_in_downtime = get_names_in_downtime(data_arr)
		# 	for i in 0..names_in_downtime.length
		# 		if 
		# 		end
		# 	end
		# end
	end
	sleep 300
end
puts " [done]"

# $Session.subreddit($Subreddit).search('linux', sort: :new, limit: 1)\
# 	.each do |submission|
# 	puts
# 	puts summarize_post(submission)
# end
