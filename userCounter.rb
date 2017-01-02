#!/usr/bin/ruby
require "cgi"
require "json"

# ユーザ毎の閲覧数を管理するクラス
class UserCounter
  # こんな感じのJSON文字列をファイル化したもの
  # [
  #   {
  #     "visited_count" : 1,
  #     "info" : { "ip" : "192.168.1.1" }
  #   },
  #   {
  #     "visited_count" : 2,
  #     "info" : { "ip" : "192.168.2.1" }
  #   }
  # ]
  USER_DB = "counter.db"
  COOKIE_COUNT_FIELD = "browse_count"
  DB_KEYS = { visited_count: "visited_count",
              user_info:     "info",
              ipaddress:     "ip" }

  # コンストラクタ
  #
  # === Parameters:
  # cgi::
  #  CGIクラスインスタンス
  def initialize(cgi)
    @cgi = cgi
    @current_user_info = {}
    @current_user_info[DB_KEYS[:ipaddress]] = cgi.remote_addr
    #@ip = cgi.remote_addr
    @counter = 0
  end

  # データベースからのユーザ情報読み出し
  #
  # === Parameters:
  #  なし
  #
  # === Returns:
  # 成功時::
  #   ユーザ情報リスト
  def readDb
    userList = []
    if File.exist?(USER_DB)
      userList = open(USER_DB) do |db|
        JSON.load(db)
      end
    end

    return userList
  end

  # クッキーから閲覧回数を読みだしてインクリメント
  #
  # === Parameters:
  #  なし
  #
  # === Returns:
  # 成功時::
  #   現在アクセスしているユーザのクッキーに残っている閲覧回数
  def countUpUserByCookie
    counter = 0

    if @cgi.cookies.include?(COOKIE_COUNT_FIELD)
      # クッキーにカウンタフィールドが存在した場合
      # カウンタ値を取得してインクリメントしてクッキーに設定
      counter = @cgi.cookies[COOKIE_COUNT_FIELD].first
      counter = counter.to_i + 1
      @cgi.cookies[COOKIE_COUNT_FIELD][0] = counter.to_s
    else
      # クッキーにカウンタフィールドが存在していない場合
      # カウンタ値を1で初期化してクッキーに設定
      counter = 1
      @cgi.cookies = [
        CGI::Cookie::new({
            'name'       => COOKIE_COUNT_FIELD,
            'value'      => counter.to_s,
        })
      ]
    end

    return counter
  end

  # DBから閲覧回数を読みだしてインクリメント
  #
  # === Parameters:
  #  userList::
  #    DBから読みだしたユーザ情報リスト
  #
  # === Returns:
  # 成功時::
  #   現在アクセスしているユーザのDBで管理されている閲覧回数
  def countUpUserByIPAddress(userList)
    found = false
    counter = 0

    userList.each do |user|
      if user[DB_KEYS[:user_info]] == @current_user_info
        # DBの中に現在アクセスしているユーザと一致するユーザが見つかった
        found = true
        user[DB_KEYS[:visited_count]] += 1
        counter = user[DB_KEYS[:visited_count]]
        break
      end
    end

    unless found
      # not found..
      user = {}
      user[DB_KEYS[:visited_count]] = 1
      user[DB_KEYS[:user_info]] = {}
      user[DB_KEYS[:user_info]][DB_KEYS[:ipaddress]] = @current_user_info[DB_KEYS[:ipaddress]]
      userList << user

      counter = user[DB_KEYS[:visited_count]]
    end

    return counter
  end

  # 新しいユーザ情報リストでDBの内容を更新
  #
  # === Parameters:
  #  userList::
  #    DBに書き込むユーザ情報リスト
  #
  # === Returns:
  # なし
  def updateDb(userList)
    #@userdb = open(USER_DB, mode = "w", perm = 0755) do |db|
    @userdb = open(USER_DB, "w") do |db|
      JSON.dump(userList, db)
    end
  end

  # 新しいユーザ情報リストでDBの内容を更新
  #
  # === Parameters:
  #  なし
  #
  # === Returns:
  #  成功時::
  #    IPアドレスによる閲覧数
  #    クッキーによる閲覧数
  def countUp
    ##################################
    # IPアドレスによるユーザ管理
    ##################################
    # IPアドレスで管理しているユーザDBの読み出し
    userList = readDb

    # IPアドレスの値のよる当該ユーザの閲覧数を取得
    ipAddressCounter = countUpUserByIPAddress(userList)

    # インクリメントした閲覧数をDBに反映
    updateDb(userList) 

    ##################################
    # クッキーによるユーザ管理
    ##################################
    # クッキーに保存している当該ユーザの閲覧数を取得
    cookieCounter = countUpUserByCookie

    return ipAddressCounter, cookieCounter
  end

  def to_s
  end

end

if __FILE__ == $0
  counter = UserCounter.new(1)
  count = counter.countUp
  p count
end
