$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'zip/zip'
require 'zip/zipfilesystem'
require 'active_support'
require 'sanitize'
require 'fastimage'
require 'uri'
require 'cgi'
require 'pathname'
require 'tmpdir'
require 'mime/types'
require 'digest/md5'
require 'pathname'
require 'date'
require 'html_compressor'
require "yui/compressor"
require "sass"
require 'tempfile'

# Tools
require 'epub/tools/logger' # require first
require 'epub/tools/dom'
require 'epub/tools/file_system'
require 'epub/tools/identifier'
require 'epub/tools/path_manipulation'
require 'epub/tools/xml'
require 'epub/tools/zip_file'

# Epub
require 'epub/base'
require 'epub/file'
require 'epub/guide'
require 'epub/manifest'
require 'epub/metadata'
require 'epub/spine'
require 'epub/version'
require 'epub/item'
require 'epub/item/html'
require 'epub/item/html/link'
require 'epub/item/css'
require 'epub/item/css/sass_line'
require 'epub/item/image'
require 'epub/item/toc'
require 'epub/item/toc/element'