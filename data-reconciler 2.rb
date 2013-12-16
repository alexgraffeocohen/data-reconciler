require 'csv'
require 'fuzzystringmatch'
require 'fast-stemmer'

class Reconciler
	@@iptc_data = Hash.new
	@@stop_words = ["of", "in", "on", "and", "the", "a", "an", "across", "for", "as", "at", "by", "from"]
	def self.iptc_load
		CSV.foreach('iptc_sample.csv') do |row|
			@@dump = Array.new(row)
			iptc_term = @@dump[7].downcase
			iptc_split_term = iptc_term.split(' ')
			@@iptc_split_term_stemmed = []
			iptc_split_term.each { |word| @@iptc_split_term_stemmed.push(word.stem) }
			iptc_term_stemmed = @@iptc_split_term_stemmed.join(' ')
			@@iptc_data[iptc_term] = iptc_term_stemmed
			puts @@iptc_data
		end
	end

	def self.iptc_compare(dbp_term)
		if @@iptc_data.has_key?(dbp_term)
			puts "#{dbp_term} matched!"
			# CSV.open('matches.csv', mode = "a+") do |file|
			# 	file << [dbp_term]
			# end
		else
			dbp_split_term = dbp_term.split(' ')
			@@dbp_split_term_stemmed = []
			dbp_split_term.each { |word| @@dbp_split_term_stemmed.push(word.stem) }
			dbp_term_stemmed = @@dbp_split_term_stemmed.join(' ')
			jarrow = FuzzyStringMatch::JaroWinkler.create( :native )
			@@iptc_data.each do |iptc_term, iptc_term_stemmed|
				distance = jarrow.getDistance(iptc_term_stemmed,dbp_term_stemmed)
				if distance > 0.9 && iptc_term_stemmed.split(" ").length == dbp_term_stemmed.split(" ").length
					puts "IPTC: #{iptc_term} (#{iptc_term_stemmed}), DBPEDIA: #{dbp_term} (#{dbp_term_stemmed}): #{distance}"
					# CSV.open('matches.csv', mode = "a+") do |file|
					# 	file << [dbp_term]
					# end
				end
			end
		end
	end
end

Reconciler.iptc_load

start_time = Time.now

CSV.foreach('dbpedia_sample.csv') do |row|
	dbp_row = Array.new(row)
	dbp_term = dbp_row[1].downcase
	Reconciler.iptc_compare(dbp_term)
end

end_time = Time.now

duration = end_time - start_time
puts "Program Duration: #{duration}" # Takes about 38 minutes right now


# non fiction vs non fiction books?
# police vs policemen?
# can deal with plurals, but what about more specific categories of the same thing?


# you'll want to add DBPedia url and IPTC url at some point to matches.csv


# this will check to see if one of the strings contains words not in the other one
# db_string.split(' ').all? {|word| iptc_string.split(' ').include?(word)} == false || iptc_string.split(' ').all? {|word| db_string.split(' ').include?(word)} == false


# put each term in a set and then check if they include stop words, if included then delete


