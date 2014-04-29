require 'csv'
require 'fuzzystringmatch'
require 'fast-stemmer'
require 'set'

class Reconciler
	
	def initialize # all of the below is loaded on start of script
		@iptc_data = Hash.new
		@dbp_data = Hash.new
		# stop_words will be taken out below
		@stop_words = Set["a", "about", "across", "after", "all", "also", "an", "and", "as", "at", "be", "been", "by", "can", "for", "from", "have", "in", "into", "its", "of", "off", "on", "or", "since", "that", "the", "their", "to", "were", "where", "which", "while", "who", "with"]
		@matched_terms = []  # this will allow for filtering out of terms once they are exactly matched
		@jarrow = FuzzyStringMatch::JaroWinkler.create( :native )
		@exact_matches_csv = CSV.open('exact_matches.csv', mode = "a+")
		@stem_matches_csv = CSV.open('stem_matches.csv', mode = "a+")
		@possibles_csv = CSV.open('possible_matches.csv', mode = "a+")
	end

	def load_iptc # loads the iptc data set
		CSV.foreach('iptc_sample.csv') do |row|
			dump = Array.new(row)
			iptc_term = dump[7].downcase
			@iptc_data[iptc_term] = self.strip_term(iptc_term) # see below
		end
	end

	def load_dbp # load the dbpedia data set
		CSV.foreach('dbpedia_sample.txt', {:col_sep => "\t"}) do |row|
			dump = Array.new(row)
			dbp_term = dump[1]
			# below excludes unmatchable terms as described in summary of README
			if /(\sin\s|\sof\s|\sfrom\s|\son\s).*([A-Z]|[0-9])|.*\sby\s.*/ =~ dbp_term
				puts "SKIPPED #{dbp_term}"
				next
			end
			dbp_term.downcase!
			@dbp_data[dbp_term] = self.strip_term(dbp_term) # see below
		end
	end

	def strip_term(term) # this stems and deletes special characters from both sets of terms
		split_term = term.split(' ')
		@split_term_stemmed = []
		split_term.each do |word|
			if @stop_words.include?(word)
				next
			end
			word.gsub!(/-|,|\(|\)|:|&|'|~|"|`/, "")  # special characters are deleted
			word.gsub!(/\//, " ") # slashes are replaced with a space
			@split_term_stemmed.push(word.stem)
		end
		@split_term_stemmed.join(' ') # value outputted to load_dbp and load_iptc
	end

	def compare  # compares both sets of data based on the three criteria described in the summary of README
		@dbp_data.each do |dbp_term, dbp_term_stripped|
			if @iptc_data.has_key?(dbp_term)
				puts "EXACT MATCH - #{dbp_term}"
				@matched_terms.push(dbp_term)  # I'm only pushing the dbp_term because it is equivalent to the iptc_term
				@exact_matches_csv << [dbp_term]
			else
				@iptc_data.each do |iptc_term, iptc_term_stripped|
					if @matched_terms.include?(iptc_term)  # since the iptc_term is equivalent to the dbp_term, this check works
						next # skip term, go to the next possible iptc_term
					end
					dbp_term_set = Set.new(dbp_term_stripped.split(' '))
					iptc_term_set = Set.new(iptc_term_stripped.split(' '))
					dbp_in_iptc = dbp_term_set.subset? iptc_term_set
					iptc_in_dbp = iptc_term_set.subset? dbp_term_set
					if dbp_term_set.length == iptc_term_set.length && dbp_in_iptc && iptc_in_dbp 
					# if lengths are the same, both terms are subsets of the other
						puts "STEM MATCH - DBPEDIA: #{dbp_term} (#{dbp_term_stripped}), IPTC: #{iptc_term} (#{iptc_term_stripped})"
						@stem_matches_csv << [dbp_term, iptc_term]
					# else if stripped terms are 90% similar 
					elsif @jarrow.getDistance(iptc_term_stripped, dbp_term_stripped) > 0.90
						puts "POSSIBLE MATCH - DBPEDIA: #{dbp_term} (#{dbp_term_stripped}), IPTC: #{iptc_term} (#{iptc_term_stripped})"
						@possibles_csv << [dbp_term, iptc_term]
					end
 				end
 			end
 		end
 	end

	def close_files # this will close all files at the end of the script
		@exact_matches_csv.close
		@possibles_csv.close
		@stem_matches_csv.close
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

