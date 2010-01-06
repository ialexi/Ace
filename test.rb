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

class Slicer
  attr_accessor :images
  
  # slice performs the slicing operations, putting the images in the output directory
  def slice
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
    end
  end
  
  # dice seems like it should continue that, but I just named it dice for fun. It really sprites things.
  def dice
    
  end
end

parser = CSSParser.new("controls/progress/progress_view", "progress_view.css", "ace.light")
parser.parse

slicer = Slicer.new
slicer.images = parser.images
slicer.slice
