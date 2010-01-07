# A CSSParser object is created for every file processed. It opens the file,
# reads its contents, and can perform two actions on it: parsing and generating.
#
# The parsing step reads the file and finds references to images; this causes those
# images to be added to the object's usedImages, which is a set of images required (images
# here being hashes with arguments specified). Ruby's "Set" functionality seems
# to work here (I am not a ruby expert, hence 'seems')
# 
# Internally, it actually generates an in-memory CSS file in the parsing step,
# to be used in the generating step—but that's all transparent. The object is long-lived,
# staying around from initial parse step to generation.

require 'pathname'
require 'set'

class CSSParser
  attr_accessor :images, :contents
  def initialize(directory, file, theme)
    @directory = directory
    @file = file
    @theme = theme
    @images = {  }
  end
  
  def parse
    # first, read file
    file = File.new(@directory + "/" + @file)
    contents = ""
    file.each {|line| contents += line}
    @contents = contents
    
    self.parse_rules
    self.parse_sprites
  end
  
  def parse_rules
    # parses @theme "name"
    # and @view(viewname)
    contents = @contents
    
    view_rule = /@view\(\s*(["']{2}|["'].*?[^\\]"|[^\s]+)\s*\)/
    
    theme_name = @theme
    contents.gsub!(view_rule) do |match|
      ".sv-view." + $1 + "." + theme_name
    end
    
    @contents = contents
  end
  
  def parse_sprites
    contents = @contents
    
    # A whole regexp would include: ([\s,]+(repeat-x|repeat-y))?([\s,]+\[(.*)\])?
    # but let's keep it simple:
    sprite_directive = /sprite\(\s*(["']{2}|["'].*?[^\\]"|[^\s]+)(.*?)\s*\)/
    contents = contents.gsub(sprite_directive) do | match |
      # prepare replacement string
      replace_with_prefix = "sprite_for("
      replace_with_suffix = ")"
      
      # get name and add to replacement
      image_name = $1
      args = $2
      image_name = $1.sub(/^["'](.*)["']$/, '\1')
      
      result_hash = { 
        :path => @directory + "/" + image_name, :image => image_name,
        :repeat => "no-repeat", :rect => [], :target => ""
      }
      
      # Replacement string is made to be replaced again in a second pass
      # first pass generates manifest, second pass actually puts sprite info in.
      
      # match: key words (Separated by whitespace) or rects.
      args.scan(/(\[.*?\]|[^\s]+)/) {|r|
        arg = $1.strip
        if arg.match(/^\[/)
          # A rectangle specifying a slice
          full_rect = []
          params = arg.gsub(/^\[|\]$/, "").split(/[,\s]+/)
          if params.length == 1
            full_rect = [params[0].to_i, 0, 0, 0]
          elsif params.length == 2
            full_rect = [params[0].to_i, 0, params[1].to_i, 0]
          elsif params.length == 4
            full_rect = params
          else
            
          end
          
          result_hash[:rect] = full_rect
        else
          # a normal keyword, probably.
          if arg == "repeat-x"
            replace_with_suffix << " repeat-x"
            result_hash[:repeat] = "repeat-x"
          elsif arg == "repeat-y"
            replace_with_suffix << " repeat-y"
            result_hash[:repeat] = "repeat-y"
          end
        end
      }
      
      image_key = result_hash[:repeat] + ":" + result_hash[:rect].join(",") + ":" + result_hash[:path]
      replace_with = replace_with_prefix + image_key + replace_with_suffix
      @images[image_key] = result_hash
      
      replace_with
    end
    
    @contents = contents
  end
  
  def generate
    
  end
end


# The Slicer object takes a set of images and slices them as needed, producing a set of images
# located in a hierarchy (for debugging purposes) in the output directory.
# The name will be: (output)/path/to/image.png_slice_rect_here.png
require 'RMagick'
require 'FileUtils'
require 'pp'

class Slicer
  attr_accessor :images
  
  # slice performs the slicing operations, putting the images in the output directory
  def slice
    image_set = []
    @images.each do |key, definition|
      path = definition[:path]
      
      x, y, width, height = 0, 0, 0, 0
      if definition[:rect].length > 0
        x, y, width, height = definition[:rect]
      end
      
      
      print "Processing " + path + "...\n"
      
      begin
        images = Magick::ImageList.new(path)
        if images.length < 1
          print "Could not open; length: ", images.length, "\n"
          next
        end
      rescue
        print "Could not open the file.\n"
        next
      end
      
      image = images[0]
      
      image_width, image_height = image.columns, image.rows
      if width == 0 then width = image_width end
      if height == 0 then height = image_height end
      if x < 0 then x = image_width + x end
      if y < 0 then y = image_height + y end
      
      result = image.crop(x, y, width, height)
      print "Writing...\n"
      FileUtils.mkdir_p "output/" + File.dirname(path)
      result.write("output/" + path + "_" + [x, y, width, height].join("_") + ".png")
      
      definition[:width] = width
      definition[:height] = height
      definition[:key] = key
      image_set << definition
    end
    
    @images = image_set
  end
  
  # dice seems like it should continue that, but I just named it dice for fun. It really sprites things.
  def dice
    # way we try:
    # the config passed to us in @config has a list of "tries".
    # 
    # Each "try" is a set of settings with which to attempt to generate a plan.
    # The wasted space that is returned with the plan is used to determine which method to use.
    # The spriter will usually try a x-repeat with the normal images first, then separate.
    #
    # Settings work as follows: an aim parameter specifies a multiple of a) the image width
    # b) the least common multiplier of all repeat pattern widths.
    tries = []
    10.times {|i| tries << {:aim=>i + 1} }
    
    images = @images
    
    ximages = images.select {|v| v[:repeat] == "repeat-x" }
    yimages = images.select {|v| v[:repeat] == "repeat-y" }
    nimages = images.select {|v| v[:repeat] == "no-repeat" }
    
    plans = []
    tries.each {|try|
      # we will have either 2 or three images in any case. So,
      # we need to pick the best case: the smallest possible primary image.
      plans << [self.plan(ximages + nimages, try), self.plan(yimages, try)]
      plans << [self.plan(nimages, try), self.plan(ximages, try), self.plan(yimages, try)]
      
    }
    
    # sort by wasted space. The least wasted is the one we want.
    plans.sort! {|a, b|
      total_wasted_a = 0
      total_wasted_b = 0
      a.each {|e| total_wasted_a += e[:wasted] }
      b.each {|e| total_wasted_b += e[:wasted] }
      
      total_wasted_a <=> total_wasted_b
    }
    
    pp plans[0]
  end
  
  # Settings={:direction=>}
  # Returns: {:wasted=>percent, :plan=>collection of clones of image hashes w/plan setings }
  # Wasted is the amount of a) empty space and b) extra space used by repeating patterns.
  # The width of the image is either a) the width of the 
  def plan(images, settings)
    # we go in direction: settings[:direction]. We sort the images first, biggest to smallest
    # based on their directional size (i.e. width for horizontal).
    # the first image in the sorted set is used to figure out the width or height of the image
    # (also using the config's units prop)
    wasted_pixels = 0
    plan = [] # images
    
    # Handle no images
    if images.length < 1
      return {:wasted=>0, :plan=>plan}
    end
    
    # sort images
    images = images.sort {|a, b|
      res = a[:repeat] <=> b[:repeat] # keep non-repeats together (at end).
      if res == 0
        res = b[:width] <=> a[:width]
        if res == 0
          res = b[:height] <=> a[:height] # sort these to get like ones together
        end
      end
      res
    }
    
    lcm = 1
    images.each {|image|
      if image[:repeat] == "repeat-x"
        lcm = lcm.lcm image[:width]
      end
    }
    
    # get unit (row/col) size
    
    unit_size = images[0][:width]
    unit_size = unit_size.lcm lcm
    
    total_width = unit_size * settings[:aim] # 1 is probably best... but we try many :)
    
    
    x = 0
    y = 0 # the current total secondary
    row_height = 0 # the current unit secondary
    
    # loop through images
    images.each {|image|
      width = image[:width]
      height = image[:height]
      
      if x + width > total_width or (image[:repeat] == "repeat-x" and x > 0)
        # make way!
        wasted_pixels += (total_width - x) * row_height
        x = 0
        y += row_height
        row_height = 0
      end
      
      img = image.dup
      
      # Set position
      img[:x] = x
      img[:y] = y
      
      # handle repeated images
      if img[:repeat] == "repeat-x" then
        img[:width] = total_width
        wasted_pixels += (total_width - width) * height
      else
        img[:width] = width
      end
      
      # height!
      img[:height] = height
      
      # add to plan
      plan << img
      
      
      x += img[:width]
      row_height = [row_height, height].max
    }
    if x > 0
      wasted_pixels += (total_width - x) * row_height
      y += row_height
    end

    return {:plan=>plan, :wasted=>wasted_pixels}
  end
end

parser = CSSParser.new("controls/progress/progress_view", "progress_view.css", "ace.light")
parser.parse

slicer = Slicer.new
slicer.images = parser.images
slicer.slice
slicer.dice
