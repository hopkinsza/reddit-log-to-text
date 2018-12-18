class RedditLog
	public
	# Assumes these are defined:
	# $Session, a redd session
	# $Post_Downtime
	#
	##############################################
	# File things
	# #new(subreddit): load or create and populate log file
	# #log: log text to botton of the file
	# #fetch_new_posts: fetch and log new posts
	################################
	# Load file, populate if empty
	def initialize(subreddit)
		@subreddit = subreddit
		# the file containing data
		@file_name = @subreddit + '-data'
		# file containing the line num.
		# of the blank line after the oldest relevant post
		# to check for $Post_Downtime violations
		@line_file_name = @file_name + '-line'

		# open file or create & populate if it doesn't exist
		if File.exist?(@file_name)
			puts "./#{@file_name} found"
		else
			print "populating ./#{@file_name} with up to 100 initial entries..."
			arr_to_write = []

			$Session.subreddit(@subreddit).search('all', sort: :new, limit: 100).reverse_each do |submission|
				arr_to_write.push summarize_post(submission)
			end
			File.open(@file_name, "a") do |f|
				arr_to_write.each do |str|
					f.write(str)
				end
			end
			# record line
			File.open(@line_file_name, "a") do |f|
				f.write("0")
			end
			puts " [done]"
		end
	end

	def fetch_new_posts
		print "fetching new posts..."
		# log posts since latest logged post, oldest first
		begin
			data_arr = File.readlines(@file_name)
			latest_id = data_arr[data_arr.length - 4]
			log_me = ""
			$Session.subreddit(@subreddit).search('all', sort: :new, after: latest_id)\
				.reverse_each do |post|
				log_me += summarize_post(post)
			end
			log(log_me)
		end
		puts " [done]"
	end

	def check_violations
		if $Post_Downtime >= 0
			print "checking logged posts for $Post_Downtime violations..."
			data_arr = File.readlines(@file_name)
			# get info from necessary logged posts to test,
			# sorted oldest first
			checkline = File.read(@line_file_name).to_i
			names = []
			times = []
			ids   = []
			begin
				i = checkline
				while i <= data_arr.length
					if i % 7 == 0
						names.push data_arr[i]
					elsif i % 7 == 1
						times.push data_arr[i].to_i
					elsif i % 7 == 2
						ids.push data_arr[i]
					end
					i += 1
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

			# set @line_file_name again
			begin
				# default to oldest post
				new_line = 0

				last_logged_time = data_arr[data_arr.length - 6].to_i
				i = data_arr.length - 6
				while i >= 1
					if (i % 7 == 1) && (last_logged_time - data_arr[i].to_i > $Post_Downtime)
						new_line = i - 1
					end
					i -= 7
				end

				File.write(@line_file_name, new_line.to_s)
			end
		else
			print "skipping $Post_Downtime checks..."
		end
		puts " [done]"
	end

	private
	##############################################
	# private methods
	#
	# #log(text)
	# log to bottom of file
	#######################
	def log(text)
		File.open(@file_name, "a") do |f|
			f.write(text)
		end
	end

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
		# 
		str = post.author.name + "\n"
		secs = post.created_utc.to_i
		str += secs.to_s + "\n"
		str += post.id + "\n"
		str += local_and_utc(secs) + "\n"
		str += post.title + "\n"
		str += post.selftext.gsub(/\n/, "") + "\n"
		str += "\n"
		return str
	end
	##############################################
	# $Post_Downtime things
	#######################
	private
	def remove_post_and_pm(post)
		post.author.send_message(subject: ("r/" + @subreddit + " post has been removed"),
			text: "Your post, \"#{post.title}\", has been removed for being posted within #{$Post_Downtime} seconds of your last submission.",
			from: nil)

		post.remove(spam: false)
		puts "removed post:"
		puts "author: #{post.author.name}"
		puts "time  : #{post.created_utc}"
		puts "title : #{post.title}"
		puts
	end
end
