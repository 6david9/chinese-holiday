require 'json'
require 'yaml'
require 'httparty'
require 'nokogiri'

def download(url)
  unless Dir.exist?("pages")
    Dir.mkdir("pages")
  end
  
  # md5 of url
  name = Digest::MD5.hexdigest(url)
  path = "pages/#{name}.htm"
  if File.exist?(path)
    return IO.read(path)
  end
  
  response = HTTParty.get(url)
  body = response.body
  
  # save body to path
  IO.write(path, body)
  
  body
end

def save_holiday(year, dict)
  unless Dir.exist?("holidays")
    Dir.mkdir("holidays")
  end
  
  path = "holidays/#{year}.yaml"
  File.write(path, dict.to_yaml)
end

def parse_html(text)
  html = Nokogiri::HTML(text)
  lines = html.css('div.pages_content p')
  content = lines.map { |line| line.text.strip }.compact.join("\n")
  parse_holiday(content)
end

def dates_between(start_date, end_date)
  dates = []
  current_date = start_date
  
  while current_date <= end_date
    dates << current_date.strftime("%Y%m%d")
    current_date += 1
  end
  
  dates
end

def parse_holiday_line(year, line)
  result = {}
  
  # 二、春节：1月21日至27日放假调休，共7天。1月28日（星期六）、1月29日（星期日）上班。
  line.scan(/[一|二|三|四|五|六|七|八|九]、(.*?)\s*[:|：]\s*(\d+)月(\d+)日至(\d+)日放假/) do |holiday, month, start_day, end_day|
    start_date = Date.new(year, month.to_i, start_day.to_i)
    end_date = Date.new(year, month.to_i, end_day.to_i)
    dates = dates_between(start_date, end_date)
    
    result["name"] = holiday
    result["dates"] = dates
  end
  
  # 一、元旦：2022年12月31日至2023年1月2日放假调休，共3天。
  line.scan(/[一|二|三|四|五|六|七|八|九]、(.*?)\s*[:|：]\s*(\d+)年(\d+)月(\d+)日至(\d+)年(\d+)月(\d+)日放假/) do |holiday, start_year, start_month, start_day, end_year, end_month, end_day|
    start_date = Date.new(start_year.to_i, start_month.to_i, start_day.to_i)
    end_date = Date.new(end_year.to_i, end_month.to_i, end_day.to_i)
    dates = dates_between(start_date, end_date)
    
    result["name"] = holiday
    result["dates"] = dates
  end
  
  # 四、劳动节：4月29日至5月3日放假调休，共5天。4月23日（星期日）、5月6日（星期六）上班。
  line.scan(/[一|二|三|四|五|六|七|八|九]、(.*?)\s*[:|：]\s*(\d+)月(\d+)日至(\d+)月(\d+)日放假/) do |holiday, start_month, start_day, end_month, end_day|
    start_date = Date.new(year, start_month.to_i, start_day.to_i)
    end_date = Date.new(year, end_month.to_i, end_day.to_i)
    dates = dates_between(start_date, end_date)
    
    result["name"] = holiday
    result["dates"] = dates
  end
  
  # 三、清明节：4月5日放假，共1天。
  line.scan(/[一|二|三|四|五|六|七|八|九]、(.*?)\s*[:|：]\s*(\d+)月(\d+)日放假/) do |holiday, month, day|
    date = Date.new(year, month.to_i, day.to_i)
    result["name"] = holiday
    result["dates"] = [date.strftime("%Y%m%d")]
  end
  
  # 二、春节：1月21日至27日放假调休，共7天。1月28日（星期六）、1月29日（星期日）上班。
  line.split("。").filter {|sent| sent.include? "上班"}.each do |sent|
    workdays = []

    sent.scan(/(\d+)月(\d+)日（星期.+?）/) do |matches|      
      month = matches[0]
      day = matches[1]
      
      date = Date.new(year, month.to_i, day.to_i)
      workdays << date.strftime("%Y%m%d")
    end
    result["workdays"] = workdays
  end
  
  result.empty? ? nil : result
end

def parse_holiday(text)
  puts text

  holiday_data = []
  year = nil
  
  text.scan(/关于(\d{4})年/) do |y|
    year = y.first.to_i
    break
  end
  
  if year.nil?
    STDERR.puts text
    raise "cannot find year" 
  end
  
  lines = text.split("\n").map{ |line| line.strip}.reject { |line| line.empty? }
  lines.each do |line|
    result = parse_holiday_line(year, line)
    holiday_data << result unless result.nil?
  end
  
  return nil if holiday_data.empty?
  
  [year, holiday_data]
end


if ARGV.length != 1
  STDERR.puts "Usage: ruby parse.rb <url>"
  exit 1
end

url = ARGV[0]
content = download(url)
payload = parse_html(content)

year = payload[0]
holidays = payload[1]

save_holiday(year, holidays)