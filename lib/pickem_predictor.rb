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
                :url            => root_url + links[0].attributes['href'].text,
                :name           => links[1].text,
                :current_score  => 0,
                :max_score_left => 0,
                :picks          => []
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
                    :name          => cells[0].text,
                    :when          => cells[4].text,
                    :home          => cells[6].search('a').text,
                    :visitor       => cells[2].search('a').text,
                    :confidence    => cells[7].search('.confidencePoints .value').text,
                    :guess         => visitor_classes.include?('empty') ? :home : :visitor,
                    :guess_status  => (visitor_status.empty?) ? home_status.first : visitor_status.first
                }
            end
        end

        puts "Entries:"
        players.each_with_index do |player, index|
            puts "[#{index}] #{player[:name]}"
        end

        print "Please select your entry [0-#{players.count - 1}]: "
        selection = gets.gsub(/\s/, '')

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

        num_columns     = players.count + 2
        max_bowl_length = players.first[:picks].inject('') do |result, pick|
            result = ((pick[:name] + " Bowl").size > result.size) ? pick[:name] + " Bowl" : result
        end.size + 1
        line_break      = '-' * ((num_columns - 1) * COLUMN_LENGTH + max_bowl_length)

        puts
        print 'Bowl Name'.ljust(max_bowl_length)
        puts self.format(
            players.map{ |player| player[:name] } + ['Your Pick']
        )
        puts line_break
        (0...players.first[:picks].count).each do |pick_index|
            fulcrum_guess = players.first[:picks][pick_index][:guess]

            print (players.first[:picks][pick_index][:name] + " Bowl").ljust(max_bowl_length)
            puts self.format(
                players.map{ |player|
                    pick = player[:picks][pick_index]
                    case pick[:guess_status] when 'correct'
                        player[:current_score] += pick[:confidence].to_i

                        "+#{pick[:confidence]}"
                    when 'wrong-pick'
                        "0"
                    else
                        guess_confidence = (pick[:guess] == fulcrum_guess) ? "+#{pick[:confidence]}" : "0"
                        player[:max_score_left] += pick[:confidence].to_i

                        "(#{guess_confidence})"
                    end 
                } +
                [players.first[:picks][pick_index][fulcrum_guess]]
            )
        end
        puts line_break
        print "Current Score".ljust(max_bowl_length)
        puts self.format(
            players.map{ |player| player[:current_score].to_s }
        )
        print "Max Possible Score".ljust(max_bowl_length)
        puts self.format(
            players.map{ |player| (player[:max_score_left] + player[:current_score]).to_s }
        )
        puts
    end

    def self.format(args)
        args.flatten.inject('') { |result, arg| result + arg.ljust(COLUMN_LENGTH) }
    end
end

Pickem.predict
