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

CLEAN_MAKE_CMD  = 'make clean && make'
MAKE_CMD        = 'make'

@in_place = true

def is_cpp_source_file(file)
    extname = File.extname(file)
    return [
            '.h',
            '.hpp',
            '.hxx',
            '.c',
            '.cpp',
            '.cxx',
           ].include?(extname)
end

def test_clean_make()
    stdin, stdout, stderr = Open3.popen3(CLEAN_MAKE_CMD)
    errors = stderr.readlines
    $stderr.puts errors if errors.size > 0
    return errors.size == 0
end

def test_make()
    stdin, stdout, stderr = Open3.popen3(MAKE_CMD)
    errors = stderr.readlines
    return errors.size == 0
end

def write_to_file(lines, file)
    File.open(file, 'w') do |f|
        f.puts(lines)
    end
end

def parse_file(file)
    puts "parse #{file} ..."

    orig_file = file + '.orig'
    FileUtils.cp(file, orig_file)

    orig_lines  = IO.readlines(orig_file)
    ok_lines    = Array.new(orig_lines)
    i           = 0
    j           = 0

    while i < ok_lines.size
        line = ok_lines[i]

        if line !~ /^\s*#\s*include\s+/ && line !~ /^\s*using\s+namespace\s+/
            i += 1
            next
        end

        lines = Array.new(ok_lines)
        lines.delete_at(i)
        write_to_file(lines, file)

        if test_make()
            $stderr.printf("    [#{@in_place ? 'removed' : 'removable'}] %s(%d): %s\n", file, i + j + 1, line.chomp)
            ok_lines = lines
            j += 1
        else
            i += 1
        end
    end

    if @in_place
        write_to_file(ok_lines, file)
        FileUtils.rm_f(orig_file)
    else
        FileUtils.mv(orig_file, file)
        FileUtils.touch(file)
    end
end

def main(argv)
    if !test_clean_make()
        $stderr.puts 'Make sure make successfully first'
        return -1
    end

    argv = ['.'] if argv.size == 0

    argv.each { |dir|
        Find.find(dir) { |file|
            parse_file(file) if File.file?(file) && is_cpp_source_file(file)
        }
    }
end

# run main
main(ARGV)
