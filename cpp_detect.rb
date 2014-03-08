#!/usr/bin/env ruby
# encoding: UTF-8
#
# Features
#   - detect unnecessary c/c++ includes
#   - detect unnecessary using namespaces
#
# Usage:
#   ruby ./cpp_detect.rb <source_dirs>
#
# Examples:
#   ruby ./cpp_detect.rb src include
#

require 'find'
require 'fileutils'
require 'open3'

def is_cpp_source_file(file)
    extname = File.extname(file)
    return [
            '.h',
            '.hxx',
            '.c',
            '.cpp',
            '.cxx',
           ].include?(extname)
end

def test_file(file)
    stdin, stdout, stderr = Open3.popen3('make')
    return stderr.readlines.size == 0
end

def parse_file(file)
    puts "parse #{file} ..."

    orig_file = file + '.orig'
    FileUtils.cp(file, orig_file)

    orig_lines = IO.readlines(orig_file)
    ok_lines   = Array.new(orig_lines)
    i          = 0

    while i < ok_lines.size
        line = ok_lines[i]

        if line !~ /^\s*#\s*include\s+/ && line !~ /^\s*using\s+namespace\s+/
            i += 1
            next
        end

        lines = Array.new(ok_lines).delete_at(i)

        File.open(file, 'w+') do |f|
            f.puts(lines)
        end

        if test_file(file)
            printf("%04d: %s", i, line)
            ok_lines = lines
        else
            i += 1
        end
    end

    FileUtils.mv(orig_file, file)
end

def main(argv)
    argv.each { |dir|
        Find.find(dir) { |file|
            parse_file(file) if File.file?(file) && is_cpp_source_file(file)
        }
    }
end

# run main
main(ARGV)

