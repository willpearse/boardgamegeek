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


got_games = 0; curr_page = 7; rank = 601

CSV.open(options[:output], "w") do |row|
  row << ["rank", "ID", "name", "year", "mechanics", "families", "categories", "n.ratings", "rating", "bayes.rating", "owned", "min_players","max_players","play_time","min_play_time","max_play_time", "one.player","two.players","three.players","four.players","many.players", "age", "language", "n.weight","weight"]

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
      year = game.css("yearpublished").text.to_i

      min_players = game.css("minplayers").text.to_i
      max_players = game.css("maxplayers").text.to_i
      play_time = game.css("playingtime").text.to_i 
      min_play_time = game.css("minplaytime").text.to_i
      max_play_time = game.css("maxplaytime").text.to_i
      
      n_ratings = game.css("usersrated").text.to_i
      rating = game.css("average").text.to_f
      bayes_rating = game.css("bayesaverage").text.to_f
      owned = game.css("owned").text.to_i

      one_player = [1,3,5].map {|x| game.css("results[numplayers='1']")[0].children[x].attributes["numvotes"].text.to_i}.join "|"
      begin
        two_players = [1,3,5].map {|x| game.css("results[numplayers='2']")[0].children[x].attributes["numvotes"].text.to_i}.join "|"
      rescue
        two_players = "NA"
      end
      begin
        three_players = [1,3,5].map {|x| game.css("results[numplayers='3']")[0].children[x].attributes["numvotes"].text.to_i}.join "|"
      rescue
        three_players = "NA"
      end
      begin
        four_players = [1,3,5].map {|x| game.css("results[numplayers='4']")[0].children[x].attributes["numvotes"].text.to_i}.join "|"
      rescue
        four_players = "NA"
      end
      begin
        many_players = [1,3,5].map {|x| game.css("results[numplayers='4+']")[0].children[x].attributes["numvotes"].text.to_i}.join "|"
      rescue
        many_players = "NA"
      end
      age = [1,3,5,7,9,11,13,15,17].map {|x| game.css("poll[name='suggested_playerage']").children[1].children[x]["numvotes"].to_i}.join "|"
      language = [1,3,5,7,9].map {|x| game.css("poll[name='language_dependence']").children[1].children[x]["numvotes"].to_i}.join "|"

      weight = game.css("averageweight").text.to_f
      n_weight = game.css("numweight").text.to_i

      
      row << [rank, id, name, year, mechanics, families, categories, n_ratings, rating, bayes_rating, owned, min_players,max_players,play_time,min_play_time,max_play_time, one_player,two_players,three_players,four_players,many_players, age, language, n_weight, weight]
      
      got_games += 1
      rank += 1
      if got_games >= options[:number] then break end
      sleep(options[:delay])
    end
    
    curr_page += 1
  end
end

puts "Finshed!"
