# Controller.rb
# LogPlot
#
# Created by koji on 11/01/19.
# Copyright 2011 __MyCompanyName__. All rights reserved.


class Controller
	attr_accessor :chk_log, :view
	def awakeFromNib()
		@chk_log.state = NSOnState
		#@view_toggleLog
		puts "hello"
	end

	def log_changed(sender)

		@view.toggleLog
		if (@view.log?)
			puts "Not Implemented Yet"
		end
	end
end