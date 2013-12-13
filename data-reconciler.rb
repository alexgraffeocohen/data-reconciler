require 'set'
require 'csv'
require 'fuzzystringmatch'
require 'fast-stemmer'

class Reconciler
	@@dump = []
	@@iptc_set = Set[] # make this into a hash with non-stemmed key and stemmed as value
	def self.iptc_load
		CSV.foreach('iptc.csv') do |row|
			@@dump = row
			iptc_value = @@dump[7].downcase 
			@@iptc_set.add(iptc_value)
		end
	end

	def self.iptc_check(value)
		if @@iptc_set.include?(value)
			puts "true"
		else
			puts "false"
		end
	end

	def self.iptc_compare(dbpedia_value)
		if @@iptc_set.include?(dbpedia_value)
			puts "match!"
			CSV.open('matches.csv', mode = "a+") do |file|
				file << [dbpedia_value]
				# you'll want to add DBPedia url and IPTC url
			end
		else
			jarrow = FuzzyStringMatch::JaroWinkler.create( :native )
			@@iptc_set.each do |iptc_value|
				distance = jarrow.getDistance(iptc_value,dbpedia_value.downcase)
				if distance > 0.9
					puts "IPTC: #{iptc_value}, DBPEDIA: #{dbpedia_value}: #{distance}"
				end
			end
		end
	end
end

Reconciler.iptc_load

start_time = Time.now

CSV.foreach('dbpedia_category_labels.csv') do |row| #stem dbpedia terms here, then match, print non-stemmed dbpedia if matched
	dbpedia_row = Array.new(row)
	dbpedia_value = dbpedia_row[1].downcase
	Reconciler.iptc_compare(dbpedia_value)  # check if each string has the same number of words
end

end_time = Time.now

duration = end_time - start_time
puts "Program Duration: #{duration}" # Takes about 38 minutes right now


# non fiction vs non fiction books?
# police vs policemen?
# can deal with plurals, but what about more specific categories of the same thing?


# pre-process the string - take each word and stem it before running the comparison (different method)
# split by non-white space and then stem each word and then compare


