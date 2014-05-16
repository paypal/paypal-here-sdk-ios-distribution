#!/usr/bin/env ruby

# Make sure we're in the directory this file is in
Dir.chdir(File.dirname(__FILE__))
clean = FALSE
# Check if SASS is installed
`type -a sass`
if not $?.success? then
  puts <<-eos
  ************************************************************************
  ************************************************************************
  The 'sass' gem is not installed but is necessary to build the project. Please run:
    `sudo gem install sass`
  ************************************************************************
  ************************************************************************
  eos
end

ARGV.each do|parameter|
  argName, *rest = parameter.split('=' , 2)
  argValue = rest[0]
  if argName == '--clean'
    clean = TRUE
  end
end

puts "Deleting old submodules..."
`rm -rf "contrib/CSVParser/"`
`rm -rf "contrib/CardIO/"`
`rm -rf "contrib/nimbus/"`
`rm -rf "UIAutomation/contrib/"`
`rm -rf "contrib/JSONKit/"`
`rm -rf "contrib/Touchpose/"`

puts "Setting up git hooks..."
`echo "#!/bin/bash\n./format.rb --check" > ./.git/hooks/pre-commit`
`chmod +x ./.git/hooks/pre-commit`

puts "Synchronizing submodules..."
puts `git submodule sync`

puts "Updating submodules..."
puts `git submodule update --init --recursive`

puts "Setting up submodule push urls..."
puts %x( git submodule foreach '
           _url=`git config remote.origin.url | perl -ne "s/https:\\/\\/(.*?)\\/(.*)/git@\\1:\\2/g; print;"`; \
           git config remote.origin.pushurl $_url;' )

Dir.chdir("SDK/source")
command = 'ruby update-repo.rb'
if clean
  command << ' --clean'
end
system command
