require 'mechanize'

module Pickem
    def self.predict
        spider = Mechanize.new { |agent|
            agent.user_agent_alias = 'Windows Mozilla'
        }

        root_url = 'http://games.espn.go.com/bowlmania/en/'

        competitors= []
        page = spider.get(root_url + 'group?groupID=8315')

        page.search('td.entry').each do |entry|
            links = entry.search('a')

            competitors << {
                :url  => root_url + links[0].attributes['href'].text,
                :name => links[1].text,
                :picks => []
            }
        end

        competitors.each_with_index do |competitor, index|
            page = spider.get(competitor[:url])
            
            page.search('table.stats1 tbody tr').each do |bowl|
                cells = bowl.search('td')
                next if cells.size < 8

                # selected-locked, wrong-pick, correct

                visitor_classes = cells[3].search('.entryPick')[0].attributes['class'].value.split(/\s/)
                visitor_status = visitor_classes.reject{ |v| ['empty', 'entryPick', 'locked'].include?(v) }
                home_status    = cells[5].search('.entryPick')[0].attributes['class'].value.split(/\s/).reject{ |v| ['empty', 'entryPick', 'locked'].include?(v) }

                competitor[:picks] << {
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

        puts competitors.inject('') { |result, competitor| result + competitor[:name].ljust(30) }
    end
end

Pickem.predict
