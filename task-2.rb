# frozen_string_literal: true

require 'oj'
require 'set'

LARGE_DATA_FILE = 'data_samples/data_large.txt'.freeze
DATA_FILE = 'data_samples/data.txt'.freeze
RESULT_FILE = 'result.json'.freeze

class User
  USER_ATTRS = %i[first_name last_name sessions_count total_time longest_session browsers dates used_ie].freeze
  attr_accessor *USER_ATTRS

  def initialize(*args)
    @first_name = args.fetch(0, nil)
    @last_name = args.fetch(1, nil)
  end

  def data
    {
      sessionsCount: sessions_count,
      totalTime: "#{total_time} min.",
      longestSession: "#{longest_session} min.",
      browsers: browsers.map(&:upcase).sort.join(', '),
      usedIE: used_ie,
      alwaysUsedChrome: only_chrome?,
      dates: dates.sort.reverse
    }.transform_keys(&:to_s)
  end

  def only_chrome?
    browsers.all? { |b| b =~ /chrome/i }
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def filled?
    !(last_name.nil? || first_name.nil?)
  end

  def set_defaults!
    self.last_name = nil
    self.first_name = nil
    self.sessions_count = 0
    self.total_time = 0
    self.longest_session = 0
    self.browsers = []
    self.dates = []
    self.used_ie = false
  end
end

def work(file_path: DATA_FILE)
  data_file = open(file_path, 'r')
  result_file = open(RESULT_FILE, 'a+')

  json_writer = Oj::StreamWriter.new(result_file, {})
  json_writer.push_object
  json_writer.push_object('usersStats')

  all_browsers = Set.new
  total_sessions = 0
  total_users = 0
  user = User.new

  data_file.each(chomp: true) do |line|
    cols = line.split(',')

    if cols[0] == 'user'
      if user.filled?
        json_writer.push_value(user.data, user.full_name)
      end
      total_users += 1
      user.set_defaults!
      user.first_name = cols[2]
      user.last_name = cols[3]
    end

    if cols[0] == 'session'
      total_sessions += 1
      user.sessions_count += 1
      user.total_time += cols[4].to_i
      user.longest_session = user.longest_session > cols[4].to_i ? user.longest_session : cols[4].to_i
      user.used_ie = (cols[3] =~ /internet explorer/i) == 0 unless user.used_ie
      user.browsers << cols[3]
      all_browsers.add cols[3]
      user.dates << cols[5]
    end

    if data_file.eof?
      json_writer.push_value(user.data, user.full_name)
      json_writer.pop

      uniq_browsers = all_browsers.uniq
      json_writer.push_value(total_users, 'totalUsers')
      json_writer.push_value(uniq_browsers.size, 'uniqueBrowsersCount')
      json_writer.push_value(total_sessions, 'totalSessions')
      json_writer.push_value(uniq_browsers.map(&:upcase).sort.join(','), 'allBrowsers')
      json_writer.pop_all
      result_file.close
    end
  end
  data_file.close
end
