require 'json'

# https://sousuo.www.gov.cn/sousuo/search.shtml?code=17da70961a7&dataTypeId=107&searchWord=%E8%8A%82%E5%81%87%E6%97%A5%E5%AE%89%E6%8E%92

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