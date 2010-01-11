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
#
# In my opinion, this script is not that great. This is due to two reasons: it is my very
# first script written in Ruby, and I was figuring out the requirements by writing it (something
# I often do, but I usually follow that with a rewrite).
# But still, it generally works, and works with acceptable speed.



require 'css'
require 'slicedice'

require 'optparse'

config = {}
argparser = OptionParser.new {|opts|
  opts.banner = "Usage: ruby generate_theme.rb [options] theme.name"
  
  config[:output] = "output/"
  opts.on('-o', '--output', 'Set output path (default: output/)') {|out|
    out += "." if out.length == 0
    out += "/" if out[out.length - 1] != '/'
    config[:output] = out
  }
  
  config[:url_template] = "static_url(%s)"
  opts.on('-u', '--url', 'The URL template (default: static_url(%s) )') {|out|
    config[:output] = out
  }
}

argparser.parse!
if ARGV.length == 0
  puts "Error: No theme name specified. Example theme name: ace.light"
  exit
else
  config[:theme_name] = ARGV[0]
end


require 'find'
images = {}
parsers = []
Find.find('./') do |f|
  if f =~ /^\.\/(output)|\/\./
    Find.prune
  end
  if f =~ /\.css$/
    parser = CSSParser.new(File.dirname(f), File.basename(f), config)
    parsers << parser
    parser.parse
    images.merge! parser.images
  end
end

slicer = Slicer.new(config)
slicer.images = images
slicer.slice
slicer.dice

css_code = ""
parsers.each {|parser|
  parser.images = slicer.images
  css_code += parser.generate
}

File.open(config[:output] + "theme.css", "w") {|f| f.write(css_code) }