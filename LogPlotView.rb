# LogPlotView.rb
# LogPlot
#
# Created by koji on 11/01/19.
# Copyright 2011 __MyCompanyName__. All rights reserved.


#value-to pixel transformer

#...maybe name Transform is not good,,, ValueBounds, ValueWindow??
class Transform

	#transform value to the NSPoint. derived class should implement transformX, transformY
	def transform(val)
		if val.kind_of?(NSPoint)
			return NSMakePoint(transformX(val.x), transformY(val.y))
		end
	end
end

class LinearTransform < Transform
	def initialize
		@axis_min_x  =  -1
		@axis_max_x = 3
		@axis_min_y = -1
		@axis_max_y = 15
	end
	
	def setBounds(rect)
		@rect = rect
		@axis_length_x = @axis_max_x - @axis_min_x
		@axis_length_y = @axis_max_y - @axis_min_y
		@scale_x = @rect.size.width / @axis_length_x
		@scale_y = @rect.size.height / @axis_length_y
		
		@shift_x =  0 - @axis_min_x*@scale_x
		@shift_y =  0 - @axis_min_y*@scale_y
	end
	
	def x_min
		@axis_min_x
	end
	
	def x_max
		@axis_max_x
	end
	
	def y_min
		@axis_min_y
	end
	
	def y_max
		@axis_max_y
	end	
	
	
	def transformX(x)
		x * @scale_x + @shift_x
	end
	def transformY(y)
		y * @scale_y + @shift_y
	end
end

#Y log transform
class LogTransform < Transform
	def initialize
		puts "#{self.class.to_s}#initialize"
		
		#set max and min values
		@axis_min_x = -2
		@axis_max_x = 5
		@axis_min_exp_y =  -2
		@axis_max_exp_y = 3
	end
	
	#set the bound rect(rect is NSRect with unit:pixel)
	def setBounds(rect)
		@rect = rect
		
		@axis_length_x = @axis_max_x - @axis_min_x
		@scale_x = @rect.size.width / @axis_length_x
		@shift_x =  (0 - @axis_min_x)*@scale_x
		
		@axis_length_y = @axis_max_exp_y - @axis_min_exp_y
		@scale_y = @rect.size.height / @axis_length_y
		@shift_y = (0 - @axis_min_exp_y)*@scale_y
	end
	
#accessors  for values range
	def x_min
		@axis_min_x
	end
	
	def x_max
		@axis_max_x
	end
	
	def y_min_exp
		@axis_min_exp_y
	end
	
	def y_max_exp
		@axis_max_exp_y
	end
	
	def range
		return @axis_min_x, @axis_max_y, @axis_min_exp_y, @axis_max_y
	end
	
#transform to view geometory(get pixel from value)
	def transformX(x)
		x * @scale_x + @shift_x
	end
	
	def transformY(y)
		begin
			log_y = Math::log10(y)
		rescue => e
			#just for logging. this should never happen
			puts "Log10(#{y}) error"
			p e
			raise e	#throw again!
		end
		log_y*@scale_y + @shift_y
	end
	
end


class LogPlotView < NSView
	attr_accessor :log
	
	def initWithFrame(frame)
		puts "initWithFrame"
		super
		p self.frame
		self
	end
	
	def awakeFromNib()
		puts "awakeFromNib"
		@log = true

		@logTransform = LogTransform.new
		@linearTransform = LinearTransform.new		
	end
	
	def log?
		@log
	end
	
	def toggleLog
		@log = !@log
		puts "log mode" if @log
		setNeedsDisplay(true)
	end
	
	
	def drawLineWithTransformLinear(fromPoint, toPoint, color, lineWidth)
		newFromPoint = @linearTransform.transform(fromPoint)
		newToPoint = @linearTransform.transform(toPoint)
		drawLine(newFromPoint, newToPoint,color,lineWidth)
	end
	
	def drawLineWithTransformLog(fromPoint, toPoint, color, lineWidth,dash=false)
		newFromPoint = @logTransform.transform(fromPoint)
		newToPoint = @logTransform.transform(toPoint)
		drawLine(newFromPoint, newToPoint,color,lineWidth,dash)
	end
	
	def drawLine(fromPoint, toPoint ,color, lineWidth, dash=false)
		NSGraphicsContext.saveGraphicsState()
		
		line = NSBezierPath.bezierPath()
		line.lineWidth = lineWidth
		
		if (dash)
			#in case of dash, use fixed interval
			line.setLineDash([5,2],count:2,phase:0)
		end
		
		line.moveToPoint( fromPoint )
		line.lineToPoint( toPoint )
		color.set
		line.stroke
		
		NSGraphicsContext.restoreGraphicsState()
	end
		
	
	def drawRect(rect)
		
		#draw the background
		NSColor.whiteColor().set
		NSRectFill(rect)
		
		if log?
			@logTransform.setBounds(self.bounds)
			
			#draw grid
			NSGraphicsContext.currentContext.setShouldAntialias(false)
			(@logTransform.y_min_exp).step(@logTransform.y_max_exp ) do |exp|
				base_y = 10**exp
				p "base_y = #{base_y}"
				if(base_y != 1)	#base grid
					drawLineWithTransformLog( NSMakePoint(@logTransform.x_min,base_y), NSMakePoint(@logTransform.x_max, base_y), NSColor.blackColor(), 1)
				end
				
				first_grid = base_y + 10**exp
				first_grid.step(10**(exp+1)-10**exp,10**exp) do |grid_y|
					p "grid_y = #{grid_y}"
					
					#破線の始まりがx軸で0になるように、0から右方向と,0から左方向の両方を書く。
					drawLineWithTransformLog( NSMakePoint(0,grid_y), NSMakePoint(@logTransform.x_max, grid_y), NSColor.lightGrayColor(),0.1, false)
					drawLineWithTransformLog( NSMakePoint(0,grid_y), NSMakePoint(@logTransform.x_min, grid_y), NSColor.lightGrayColor(),0.1, false)

				end
			end
			NSGraphicsContext.currentContext.setShouldAntialias(true)

			#draw axis
			drawLineWithTransformLog( NSMakePoint(@logTransform.x_min, 10**0), NSMakePoint(@logTransform.x_max,10**0), NSColor.blackColor(), 3.0)
			drawLineWithTransformLog( NSMakePoint(0, 10**@logTransform.y_min_exp), NSMakePoint(0,10**@logTransform.y_max_exp), NSColor.blackColor(), 3.0)

			#draw values
			path = NSBezierPath.bezierPath()
			path.setLineWidth(2.0)
			
			firstMoved = false
			(@logTransform.x_min).step(@logTransform.x_max,0.1) do |x|
				y = 10 ** x
				
				point = @logTransform.transform(NSMakePoint(x,y))

				if (firstMoved)
					path.lineToPoint(point)
				else
					path.moveToPoint(point)
					firstMoved = true
				end
			end
			NSColor.blueColor().set
			path.stroke
			
		else
			@linearTransform.setBounds(self.bounds)
			
			#draw the axis
			drawLineWithTransformLinear( NSMakePoint(@linearTransform.x_min,0), NSMakePoint(@linearTransform.x_max,0), NSColor.blackColor(), 3.0)
			drawLineWithTransformLinear( NSMakePoint(0, @linearTransform.y_min), NSMakePoint(0, @linearTransform.y_max), NSColor.blackColor(),3.0)
			
			#TODO:draw grids
			
			#draw actual line
			path = NSBezierPath.bezierPath()
			path.setLineWidth(2.0)
			
			firstMoved = false
			@linearTransform.x_min.step(@linearTransform.x_max, 0.1) do |x|
				y = 10 ** x
				
				point = @linearTransform.transform(NSMakePoint(x,y))

				if (firstMoved)
					path.lineToPoint(point)
				else
					path.moveToPoint(point)
					firstMoved = true
				end
			end
			
			NSColor.blueColor().set
			path.stroke
		end
	end
end
