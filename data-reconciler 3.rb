require 'csv'
require 'fuzzystringmatch'
require 'fast-stemmer'
require 'set'

class Reconciler
	
	def initialize
		@iptc_data = Hash.new
		@dbp_data = Hash.new
		@stop_words = Set["a", "about", "across", "after", "all", "also", "an", "and", "as", "at", "be", "been", "by", "can", "for", "from", "have", "in", "into", "its", "of", "off", "on", "or", "since", "that", "the", "their", "to", "were", "where", "which", "while", "who", "with"]
		@matched_terms = []
		@special_characters_delete = ["-", ",", "(", ")", ":", "&", "'", "~", '"', "`"]
		@jarrow = FuzzyStringMatch::JaroWinkler.create( :native )
		@matches_csv = CSV.open('matches.csv', mode = "a+")
		@possibles_csv = CSV.open('possible_matches.csv', mode = "a+")
		@stem_matches_csv = CSV.open('stem_matches.csv', mode = "a+")
	end

	def load_iptc
		CSV.foreach('iptc.csv') do |row|
			dump = Array.new(row)
			iptc_term = dump[7].downcase
			@iptc_data[iptc_term] = self.strip_term(iptc_term)
		end
	end

	def load_dbp
		CSV.foreach('DBPedia.txt', {:col_sep => "\t"}) do |row|
			dump = Array.new(row)
			dbp_term = dump[1]
			if /(\sin\s|\sof\s|\sfrom\s|\son\s).*([A-Z]|[0-9])|.*\sby\s.*/ =~ dbp_term
				puts "SKIPPED #{dbp_term}"
				next
			end
			dbp_term.downcase!
			@dbp_data[dbp_term] = self.strip_term(dbp_term)
		end
	end

	def strip_term(term)
		split_term = term.split(' ')
		@split_term_stemmed = []
		split_term.each do |word|
			if @stop_words.include?(word)
				next
			end
			word.gsub!(/-|,|\(|\)|:|&|'|~|"|`/, "")
			word.gsub!(/\//, " ")
			@split_term_stemmed.push(word.stem)
		end
		@split_term_stemmed.join(' ')
	end

	def compare
		@dbp_data.each do |dbp_term, dbp_term_stripped|
			if @iptc_data.has_key?(dbp_term)
				puts "EXACT MATCH - #{dbp_term}"
				@matched_terms.push(dbp_term)
				@matches_csv << [dbp_term]
			elsif @iptc_data.has_value?(dbp_term_stripped)
			 		puts "STEMMED MATCH - #{dbp_term}"
			 		@stem_matches_csv << [dbp_term]
			else
				@iptc_data.each do |iptc_term, iptc_term_stripped|
					if @matched_terms.include?(iptc_term)
						break	
					end
					dbp_term_set = Set.new(dbp_term_stripped.split(' '))
					iptc_term_set = Set.new(iptc_term_stripped.split(' '))
					dbp_in_iptc = dbp_term_set.subset? iptc_term_set
					iptc_in_dbp = iptc_term_set.subset? dbp_term_set
					distance = @jarrow.getDistance(iptc_term_stripped, dbp_term_stripped)
					if dbp_term_set.length == iptc_term_set.length && dbp_in_iptc && iptc_in_dbp
						puts "STEMMED MATCH - DBPEDIA: #{dbp_term} (#{dbp_term_stripped}), IPTC: #{iptc_term} (#{iptc_term_stripped})"
						@stem_matches_csv << [dbp_term, iptc_term] 
					elsif distance > 0.90
						puts "POSSIBLE MATCH - DBPEDIA: #{dbp_term} (#{dbp_term_stripped}), IPTC: #{iptc_term} (#{iptc_term_stripped}): #{distance}"
						@possibles_csv << [dbp_term, iptc_term]
					end
				end
			end
		end
	end

	def close_files
		@matches_csv.close
		@possibles_csv.close
	end

end

start_time = Time.now

reconcile = Reconciler.new
reconcile.load_iptc
reconcile.load_dbp
reconcile.compare
reconcile.close_files

end_time = Time.now

duration = end_time - start_time
puts "Program Duration: #{duration}" 






# you'll want to add DBPedia url and IPTC url at some point to matches.csv






