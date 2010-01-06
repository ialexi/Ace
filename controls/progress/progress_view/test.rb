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
  attr_accessor :images
  def initialize(directory, file)
    @directory = directory
    @file = file
    @images = {  }
  end
  def parse
    # first, read file
    file = File.new(@file)
    contents = ""
    file.each {|line| contents += line}
    
    # A whole regexp would include: ([\s,]+(repeat-x|repeat-y))?([\s,]+\[(.*)\])?
    # but let's keep it simple:
    sprite_directive = /sprite\(\s*(["']{2}|["'].*?[^\\]"|[^\s]+)(.*?)\s*\)/
    result = contents.gsub(sprite_directive) do | match |
      # prepare replacement string
      replace_with_prefix = "sprite_for("
      replace_with_suffix = ")"
      
      # get name and add to replacement
      image_name = $1
      args = $2
      image_name = $1.sub(/^["'](.*)["']$/, '\1')
      
      result_hash = { 
        :path => @directory + "/" + image_name, :image => image_name,
        :repeat => "no-repeat", :rect => []
      }
      
      # Replacement string is made to be replaced again in a second pass
      # first pass generates manifest, second pass actually puts sprite info in.
      
      # match: key words (Separated by whitespace) or rects.
      args.scan(/(\[.*?\]|[^\s]+)/) {|r|
        arg = $1.strip
        if arg.match(/^\[/)
          # A rectangle specifying a slice
          full_rect = []
          params = arg.gsub(/^\[|\]$/, "").split(/[,\s]/)
          if params.length == 1
            full_rect = [params[0]., 0, 0, 0]
          elsif params.length == 2:
            full_rect = [params[0], 0, params[1], 0]
          elsif params.length == 4:
            full_rect = params
          else
            
          end
          result_hash["rect"] = full_rect
        else
          # a normal keyword, probably.
          if arg == "repeat-x"
            replace_with_suffix << " repeat-x"
            result_hash["repeat"] = "repeat-x"
          elsif arg == "repeat-y"
            replace_with_suffix << " repeat-y"
            result_hash["repeat"] = "repeat-y"
          end
        end
      }
      
      image_key = result_hash[:repeat] + ":" + result_hash[:rect].join(",") + ":" + result_hash[:path]
      replace_with = replace_with_prefix + image_key + replace_with_suffix
      @images[image_key] = result_hash
      
      replace_with
      # now that we have args, we need to see what they are
    end
    
    print "RESULT: " + result
  end
  
  def generate
    
  end
end


# The Slicer object takes a set of images and slices them as needed, producing a set of images
# located in a hierarchy (for debugging purposes) in the output directory.
# The name will be: (output)/path/to/image.png_slice_rect_here.png

parser = CSSParser.new("controls/progress", "progress_view.css")
print parser.parse
print parser.images