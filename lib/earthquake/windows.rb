# -*- coding: utf-8 -*-

require 'iconv'
require 'Win32API'
require "rubygems"
require "dl/import"

$wSetConsoleTextAttribute = Win32API.new('kernel32','SetConsoleTextAttribute','II','I')
$wGetConsoleScreenBufferInfo = Win32API.new("kernel32", "GetConsoleScreenBufferInfo", ['l', 'p'], 'i')
$wGetStdHandle = Win32API.new('kernel32','GetStdHandle','I','I')
$wGetACP = Win32API.new('kernel32','GetACP','','I')

$acp = $wGetACP.call()
$stdout_handle = $wGetStdHandle.call(0xFFFFFFF5)
lpBuffer = ' ' * 22
$wGetConsoleScreenBufferInfo.call($stdout_handle, lpBuffer)
$old_color = lpBuffer.unpack('SSSSSssssSS')[4]

$color_map = {
   0 => 0x07|0x00|0x00|0x00, # black/white
  37 => 0x08|0x00|0x00|0x00, # white/intensity
  31 => 0x04|0x08|0x00|0x00, # red/red
  32 => 0x02|0x08|0x00|0x00, # green/green
  33 => 0x06|0x08|0x00|0x00, # yellow/yellow
  34 => 0x01|0x08|0x00|0x00, # blue/blue
  35 => 0x05|0x08|0x00|0x00, # magenta/purple
  36 => 0x03|0x08|0x00|0x00, # cyan/aqua
  39 => 0x07,                # default
  40 => 0x00|0x00|0xf0|0x00, # background:white
  41 => 0x07|0x00|0x40|0x00, # background:red
  42 => 0x07|0x00|0x20|0x00, # background:green
  43 => 0x07|0x00|0x60|0x00, # background:yellow
  44 => 0x07|0x00|0x10|0x00, # background:blue
  45 => 0x07|0x00|0x50|0x80, # background:magenta
  46 => 0x07|0x00|0x30|0x80, # background:cyan
  47 => 0x07|0x00|0x70|0x80, # background:gray
  49 => 0x70,                # default
  90 => 0x07|0x00|0x00|0x00, # erase/white
}

$iconv_u8_to_acp = Iconv.new("CP#{$wGetACP.call()}", 'UTF-8')
$iconv_acp_to_u8 = Iconv.new('UTF-8', "CP#{$wGetACP.call()}")

def print(str)
  return if str.empty?
  str.to_s.gsub("\xef\xbd\x9e", "\xe3\x80\x9c").split(/(\e\[[\d;]*[a-zA-Z])/).each do |token|
    case token
    when /\e\[([\d;]+)m/
      $1.split(/;/).each do |c|
        color = c.to_i > 90 ? (c.to_i % 60) : c.to_i
        $wSetConsoleTextAttribute.call $stdout_handle, $color_map[color].to_i
      end
    when /\e\[\d*[a-zA-Z]/
      # do nothing
    else
      loop do
        begin
          STDOUT.print $iconv_u8_to_acp.iconv(token)
          break
        rescue Iconv::Failure
          STDOUT.print "#{$!.success}?"
          token = $!.failed[1..-1]
        end
      end
    end
  end
  $wSetConsoleTextAttribute.call $stdout_handle, $old_color
  $iconv_u8_to_acp.iconv(nil)
end

def puts(str)
  return if str.empty?
  print str
  STDOUT.puts
end

def acp_to_u8(str)
  out = ''
  loop do
    begin
      out << $iconv_acp_to_u8.iconv(str)
      break
    rescue Iconv::Failure
      out << "#{$!.success}?"
      str = $!.failed[1..-1]
    end
  end
  return out
end

def u8_to_acp(str)
  out = ''
  loop do
    begin
      out << $iconv_u8_to_acp.iconv(str)
      break
    rescue Iconv::Failure
      out << "#{$!.success}?"
      str = $!.failed[1..-1]
    end
  end
  return out
end

module Lib_MSVCRT extend DL::Importer
  LC_CTYPE = 2
  dlload "msvcrt.dll"
  extern "char* setlocale(int, char*)"
end
Lib_MSVCRT::setlocale(Lib_MSVCRT::LC_CTYPE, "")

module Readline
  alias :old_readline :readline
  def readline(*a)
    begin
      return acp_to_u8(old_readline(*a))
    rescue
      return old_readline(*a)
    end
  end
  module_function :old_readline, :readline
end
