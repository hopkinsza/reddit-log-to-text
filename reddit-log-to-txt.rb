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
	print "populating ./#{File_Name} with up to 100 initial entries..."
	arr_to_write = []

	$Session.subreddit($Subreddit).search('all', sort: :new, limit: 100)\
		.each do |submission|
		arr_to_write.push summarize_post(submission)
	end
	File.open(File_Name, "a") do |f|
		arr_to_write.each do |str|
			f.write(str)
		end
	end

	File.open(File_Name + "-line", "a") do |f|
		# $File_Name + "-line" is the line num of the blank
		# line after the oldest post we need to check
		# for $Post_Downtime violations
		f.write((arr_to_write.length * 7))
	end
	puts " [done]"
end

################################################
# Delete logged posts if they violate
# $Post_Downtime.
# Load posts every 3 minutes log them.
######################################
def log_to_top_of_file(file_name, text)
	File.open("temp", "w") do |temp|
		temp.write(text)
		temp.write(File.read(file_name))
		File.delete(file_name)
		File.rename("temp", file_name)
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
	puts "removed post:"
	puts "author: #{post.author.name}"
	puts "time  : #{post.created_utc}"
	puts "title : #{post.title}"
	puts
end

# repeats every 5 minutes, infinitely
# (until stopped with ^C)
loop do
	print "checking logged posts for $Post_Downtime violations..."
	if $Post_Downtime >= 0
		data_arr = File.readlines(File_Name)
		# get info from necessary logged posts to test,
		# sorted oldest first
		checkline = File.read(File_Name + "-line").to_i
		names = []
		times = []
		ids   = []
		begin
			i = checkline - 1
			while i >= 0
				if i % 7 == 0
					names.push data_arr[i]
				elsif i % 7 == 1
					times.push data_arr[i].to_i
				elsif i % 7 == 2
					ids.push data_arr[i]
				end
				i -= 1
			end
		end

		# test logged posts, remove post & ignore in array
		# if it violates $Post_Downtime
		for i in 0...names.length
			for j in i...names.length
				next if i == j
				if (names[i] == names[j]) && (times[i] - times[j] < $Post_Downtime) && (names[i] != "")
					post = Redd::Models::Submission.from_id($Session.client, ids[j])
					puts; remove_post_and_pm(post)
					names[i] = ""
				end
			end
		end

		# set File_Name + "-line" again
		begin
			last_logged_time = data_arr[1].to_i
			new_line = 0
			for i in 0...data_arr.length
				if (i % 7 == 1) && (last_logged_time - data_arr[i].to_i > $Post_Downtime)
					new_line = i + 5
				end
			end
			if new_line == 0
				# default to first ever logged post
				new_line = data_arr.length - 1
			end
			File.write(File_Name + "-line", new_line.to_s)
		end
	end
	puts " [done]"

	print "fetching new posts..."
	# log posts since latest logged post, oldest first
	begin
		data_arr = File.readlines(File_Name)
		latest_id = data_arr[2]
		log_me = ""
		$Session.subreddit($Subreddit).search('all', sort: :new, after: latest_id)\
			.reverse_each do |post|
			log_me += summarize_post(post)
		end
		log_to_top_of_file(File_Name, log_me)
	end
	puts " [done]"
	sleep 300
end
