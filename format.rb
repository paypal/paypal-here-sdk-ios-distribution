#!/usr/bin/env ruby
require 'optparse'

# Make sure we're in the directory this file is in
Dir.chdir(File.dirname(__FILE__))

options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: format.rb [options]"
  opts.separator "Note: With no options, format.rb formats all files with a filetype it understands that have staged git changes."
  opts.on("-a", "--all", "Format or check all files under format.rb's jurisdiction.") {|a| options[:all] = a}
  opts.on("-i", "--include-unstaged", "Include files with unstaged changes in addition to those with staged changes") {|i| options[:include_unstaged] = i}
  opts.on("-c", "--check", "Don't actually modify files, just throw an error if incorrect formatting is found.") {|c| options[:check] = c}
end

# Parse arguments and deal with exceptions.
begin
  optparse.parse!
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  puts $!.to_s
  puts optparse
  exit(2)
end

files = ""
if options[:all]
  find_command = 'find . -type f ' +
    '-not -path "./SDK/source/*" '+
    '-and \( -name "*.[mh]" -or   -name "*.js" -or  -name "*.rb"  -or  -name "*.scss" \)'
  files = `#{find_command}`.split "\n"
else
  git_files=`git diff --name-only --cached`
  if options[:include_unstaged]
    git_files+=`git diff --name-only`
  end
  files = git_files.split("\n").select {|x| not File.directory? x}
end

unformatted_files = []
files.each do |file|
  file.chomp!

  next if not File.exist?(file)
  next if File.symlink?(file)

  tmpFile = "#{file}.tmp"
  `cp -p "#{file}" "#{tmpFile}"`

  case File.extname(file)
  when ".m", ".h"
    `./contrib/objective-c-formatter/formatter.rb "#{file}" "#{tmpFile}"`
  when ".scss"
    `sass-convert --from scss --to scss "#{file}" "#{tmpFile}"`
  end

  if options[:check]
    if `diff "#{file}" "#{tmpFile}"`.length > 0
      unformatted_files << file
    end
    `rm "#{tmpFile}"`
  else
    `mv "#{tmpFile}" "#{file}"`
  end

end

if options[:check]
  if unformatted_files.count > 0
    print "Error: Files have not been formatted:"
    unformatted_files.each do |file|
      print "\n    #{file}"
    end
    print "\nRun format.rb to format all files with staged changes."
    exit 1
  else
    print "Formatting looks good to me.\n"
  end
end
