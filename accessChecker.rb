#!/usr/bin/ruby
require "./userCounter.rb"

module ResultCode
  RESULT_OK = 1
  RESULT_NG_REJECT = 2 
  RESULT_NG_OVERLIMIT = 3 
end

# ユーザのアクセス可否をチェックするクラス
class AccessChecker
  attr_reader :ipAddressCounter, :cookieCounter

  # アクセス可能回数
  PERMIT_FREEUSER_VIEW_COUNT = 300

  # 拒否IPアドレスリストファイル
  BAN_IPADDRESS_LIST = "banIpAddressList.txt"

  # コンストラクタ
  #
  # === Parameters:
  # cgi::
  #  CGIクラスインスタンス
  def initialize(cgi)
    @cgi = cgi
    @ipAddressCounter = ipAddressCounter
    @cookieCounter = cookieCounter
  end

  # 閲覧回数を超えているかチェックする
  # IPアドレスかクッキーによる閲覧数のどちらかが超えていたらNGとすする
  #
  # === Parameters:
  # ipAddressCounter::
  #  IPアドレスによる閲覧数カウント
  # cookieCounter::
  #  クッキーによる閲覧数カウント
  #
  # === Returns:
  # true::
  #   閲覧回数制限以内（閲覧を許可する）
  # false::
  #   閲覧回数制限以上（閲覧を許可しない）
  def overLimit?(ipAddressCounter, cookieCounter)
    if ( ipAddressCounter > PERMIT_FREEUSER_VIEW_COUNT ||
         cookieCounter    > PERMIT_FREEUSER_VIEW_COUNT )
      return true
    else
      return false
    end
  end
  
  # アクセス元IPアドレスが予め定義した拒否IPアドレスリストに含まれるかチェックする
  # Torのexitノードリストを別ファイルで保持しておき、弾くために利用
  #
  # === Parameters:
  # ip::
  #  アクセス元IPアドレス
  #
  # === Returns:
  # true::
  #   拒否IPアドレスリストに含まれる（閲覧を許可しない）
  # false::
  #   拒否IPアドレスリストに含まれない（閲覧を許可する）
  def containsBanIpAddressList?(ip)
    return false unless File.exist? BAN_IPADDRESS_LIST
  
    # BANリストに含まれるかどうかチェック
    File.open(BAN_IPADDRESS_LIST) do |file|
      file.each_line do |banIp|
        if ip == banIp.strip
          # 拒否IPアドレスリストのIPと一致
          return true
        end
      end
    end
  
    return false
  end


  # アクセスユーザがアクセス可能かどうかをチェックする
  #
  # === Parameters:
  #  なし
  #
  # === Returns:
  # ResultCode::RESULT_NG_OK::
  #   アクセス可能
  # ResultCode::RESULT_NG_REJECT::
  #   アクセス拒否（拒否IPアドレスリストに含まれる）
  # ResultCode::RESULT_NG_OVERLIMIT::
  #   アクセス拒否（規定回数より多くアクセスしている）
  def checkUser
    ipAddress = @cgi.remote_addr
    counter = UserCounter.new(@cgi)
    @ipAddressCounter, @cookieCounter  = counter.countUp

    # アクセス元IPアドレスが拒否IPアドレスリストに含まれるかチェック
    if containsBanIpAddressList?(ipAddress)
      # 怪しげなIPアドレスからのアクセス
      return ResultCode::RESULT_NG_REJECT
    # 閲覧回数が制限回数を超えているかチェック
    elsif overLimit?(@ipAddressCounter, @cookieCounter)
      # アクセス制限回数超え
      return ResultCode::RESULT_NG_OVERLIMIT
    else
      # アクセスOK
      return ResultCode::RESULT_OK
    end
  end

  def to_s
  end
end

if __FILE__ == $0
  checker = AccessChecker.new(1)
  checker.checkUser
end
