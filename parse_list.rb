require 'json'

[1,2,3].each do |index|
  dict = JSON.parse(File.read("list#{index}.json"))
  list = dict["result"]["data"]["middle"]["list"]
  
  list.each do |item|
    title = item["title_no_tag"]
    url = item["url"]
    pubcode = item["pubcode"]
    
    if pubcode == 14 && title.include?("国务院办公厅") && title.include?("节假日")
      puts title
      puts url
      
      system "ruby", "parse.rb", url

      puts
    end
  end
end