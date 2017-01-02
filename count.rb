#!/usr/bin/ruby

require "cgi"
require "./accessChecker.rb"

#print "Content-type: text/html;\n\n";

# CGIのエラーログ出力
def printCgiErrorLog
  print "Content-Type:text/html;charset=UTF-8\n\n"
  print "*** CGI Error List ***<br>"
  print "#{CGI.escapeHTML($!.inspect)}<br>"
  $@.each do |x| 
    print CGI.escapeHTML(x), "<br>"
  end
end

begin
  cgi = CGI.new
  ip = cgi.remote_addr
  
  checker = AccessChecker.new(cgi)
  result = checker.checkUser

  if result == AccessChecker::ResultCode::RESULT_NG_REJECT
    # 怪しげなIPアドレスからのアクセス
    print cgi.header( { 
      "status"     => "REDIRECT",
      #"Location"   => "http://localhost/reject.html"
      "Location"   => "reject.html"
    })
  elsif result == AccessChecker::ResultCode::RESULT_NG_OVERLIMIT
    # 閲覧回数の制限超え
    print cgi.header( { 
      "status"     => "REDIRECT",
      #"Location"   => "http://localhost/over.html"
      "Location"   => "over.html"
    })
  else
    # 閲覧許可
    cgi.out("cookie" => cgi.cookies) do
        "
        <p>クッキーから取得した閲覧数：#{checker.cookieCounter}</p>
        <p>IPアドレスから取得した閲覧数 #{checker.ipAddressCounter} </p>
        <p>Your IP Address is #{ip} </p>
        "
    end
  end
rescue
  printCgiErrorLog
end

