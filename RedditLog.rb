class RedditLog
	# Assumes these are defined:
	# $Session, a redd session
	# $Subreddit, the subreddit to log
	# $Post_Downtime
	#
	##############################################
	# #new: load or create and populate log file
	# #log: log text to top of the file
	# #fetch_new_posts: fetch and log new posts
	################################
	# Load file, populate if empty
	def new(subreddit)
		# the file containing data
		@file_name = $Subreddit + '-data'
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

			$Session.subreddit($Subreddit).search('all', sort: :new, limit: 100)\
				.each do |submission|
				arr_to_write.push summarize_post(submission)
			end
			File.open(@file_name, "a") do |f|
				arr_to_write.each do |str|
					f.write(str)
				end
			end

			File.open(@line_file_name, "a") do |f|
				f.write((arr_to_write.length * 7))
			end
			puts " [done]"
		end
	end

	# logs text to top of file
	def log(text)
		File.open("temp", "w") do |temp|
			temp.write(text)
			temp.write(File.read(@file_name))
			File.delete(@file_name)
			File.rename("temp", @file_name)
		end
	end
	def fetch_new_posts
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
			log(log_me)
		end
		puts " [done]"
	end

	##############################################
	# $Post_Downtime things
	#######################
	def self.remove_post_and_pm(post)
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

	def check_violations
		print "checking logged posts for $Post_Downtime violations..."
		if $Post_Downtime >= 0
			data_arr = File.readlines(@file_name)
			# get info from necessary logged posts to test,
			# sorted oldest first
			checkline = File.read(@line_file_name).to_i
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

			# set @file_name + "-line" again
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
				File.write(@line_file_name, new_line.to_s)
			end
		end
		puts " [done]"
	end
end
