#!/usr/bin/ruby
require 'optparse'
require 'json'
require 'open-uri'
require 'nokogiri'
require 'csv'

options = {}
options[:number] = 10
options[:delay] = 1

OptionParser.new do |opts|
  #Defaults
  opts.banner = "CrawlingGeek: Downloading BoardGameGeek data in descending order of importance\nUsage: crawl.rb [options]"
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
  opts.on("-n NUMBER", "--number NUMBER", "Download NUMBER entries (default: 100") {|x| options[:number] = x.to_i}
  opts.on("-d DELAY", "--delay DELAY", "How many seconds to wait between downloads (default: 1)") {|x| options[:delay] = x.to_i}
  opts.on("-o OUTPUT", "--output FILE", "Name of file to write output to") {|x| options[:output] = x.to_s}
  opts.on("-")
end.parse!


got_games = 0; curr_page = 1; rank = 1

CSV.open(options[:output], "w") do |row|
  row << ["rank", "ID", "name", "mechanics", "families", "categories", "n.ratings", "rating"]

  while got_games < options[:number]
    page = Nokogiri::HTML(open("https://boardgamegeek.com/browse/boardgame/page/#{curr_page}").read)
    
    page.css("td[class='collection_thumbnail']").each do |entry|
      game_url = entry.css("a")[0].values[0]
      game = Nokogiri::XML(open("https://www.boardgamegeek.com/xmlapi#{game_url}?stats=1").read)
      name = game_url[/[a-z0-9-]+$/]
      id = game_url[/[0-9]+/]

      puts name
      mechanics = game.css("boardgamemechanic").map {|x| x.children.text}.join "|"
      families = game.css("boardgamefamily").map {|x| x.children.text}.join "|"
      categories = game.css("boardgamecategory").map {|x| x.children.text}.join "|"
      n_ratings = game.css("usersrated").text.to_i
      rating = game.css("average").text.to_f

      row << [rank, id, name, mechanics, families, categories, n_ratings, rating]
      
      got_games += 1
      rank += 1
      if got_games >= options[:number] then break end
      sleep(options[:delay])
    end
    
    curr_page += 1
  end
end

puts "Finshed!"

