require 'csv'
require 'fast-stemmer'
require 'set'

class Reconciler
	@@dbp_data = Hash.new
	@@stop_words = Set["a", "about", "across", "after", "all", "also", "an", "and", "as", "at", "be", "been", "by", "can", "for", "from", "have", "in", "into", "its", "of", "off", "on", "or", "since", "that", "the", "their", "to", "were", "where", "which", "while", "who", "with"]
	
	def self.dbp_load
		CSV.foreach('dbpedia_category_labels.csv') do |row|
			dump = Array.new(row)
			dbp_term = dump[1].downcase
			Reconciler.strip_term(dbp_term)
			@@dbp_data[dbp_term] = @@term_stripped
		end
	end

	def self.strip_term(term)
		split_term = term.split(' ')
		@@split_term_stemmed = []
		split_term.each do |word|
			if @@stop_words.include?(word)
				next
			end
			if word.include?('-')
				word.delete!('-')
			end
			@@split_term_stemmed.push(word.stem)
		end
		@@term_stripped = @@split_term_stemmed.join(' ')
	end
end

start_time = Time.now
Reconciler.dbp_load
end_time = Time.now

duration = end_time - start_time
puts "Time: #{duration}"