require 'mechanize'

module Pickem
    COLUMN_LENGTH = 20

    def self.predict
        spider = Mechanize.new { |agent|
            agent.user_agent_alias = 'Windows Mozilla'
        }

        root_url = 'http://games.espn.go.com/bowlmania/en/'

        players= []
        page = spider.get(root_url + 'group?groupID=8315')

        page.search('td.entry').each do |entry|
            links = entry.search('a')

            players << {
                :url  => root_url + links[0].attributes['href'].text,
                :name => links[1].text,
                :picks => []
            }
        end

        players.each_with_index do |player, index|
            page = spider.get(player[:url])
            
            page.search('table.stats1 tbody tr').each do |bowl|
                cells = bowl.search('td')
                next if cells.size < 8

                # selected-locked, wrong-pick, correct

                visitor_classes = cells[3].search('.entryPick')[0].attributes['class'].value.split(/\s/)
                visitor_status = visitor_classes.reject{ |v| ['empty', 'entryPick', 'locked'].include?(v) }
                home_status = cells[5].search('.entryPick')[0].attributes['class'].value.split(/\s/).reject do |v| 
                    ['empty', 'entryPick', 'locked'].include?(v)
                end
                player[:picks] << {
                    :name         => cells[0].text,
                    :when         => cells[4].text,
                    :home         => cells[6].search('a').text,
                    :visitor      => cells[2].search('a').text,
                    :confidence   => cells[7].search('.confidencePoints .value').text,
                    :guess        => visitor_classes.include?('empty') ? :home : :visitor,
                    :guess_status => (visitor_status.empty?) ? home_status.first : visitor_status.first
                }
            end
        end

        puts "Competitors:"
        players.each_with_index do |player, index|
            puts "[#{index}] #{player[:name]}"
        end

        print "Select a player to compare others against [0-#{players.count - 1}]: "
        selection = gets

        valid_integer = (true if Integer(selection) rescue false)
        if not valid_integer
            puts "You inputted an invalid selection - defaulting to [0] (#{players[0][:name]})"
            selection = 0
        else
            selection = selection.to_i

            if selection < 0 or selection >= players.count
                puts "You inputted an invalid player number - defaulting to [0] (#{players[0][:name]})"
                selection = 0
            end
        end

        players.unshift(players.delete_at(selection))

        puts players.inject('') { |result, player| result + player[:name].ljust(COLUMN_LENGTH) }
        puts '-' * players.count * COLUMN_LENGTH
        
        max_bowl_length = players.first[:picks].inject('') do |result, pick|
            # !!!
        end

        (0...players.first[:picks].count).each do |bowl_index|
            row = 

            (0...players.count).each do |player_index|
                
            end
        end
    end
end

Pickem.predict
