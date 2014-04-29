# IPTC - DBpedia Data Reconciler

## Summary
This script slurps a CSV file of IPTC media topics and a TSV of DBPedia topics into hashes and compares them to one another to find potential matches. It first filters out DBPedia terms that are too specific and would never map to IPTC topics (i.e. terms specified with proper nouns and/or years, like "Shipbuilders in Italy" or "Armenian history since 1950"). After loading both data sets into hashes, it then checks for an exact match with a hash key lookup and logs such terms to 'exact_matches.csv'. If that doesn't work, it checks for a 'stemmed' match between two terms, and logs such cases to 'stem_matches.csv'. If neither check works, it logs terms whose stems are more than 90% similar based on a fuzzy string match test to 'possible_matches.csv'. As it's currently implemented, there will unfortunately be some duplicates between 'stem_matches.csv' and 'possible_matches.csv', but an exactly matched term will not appear on either of those other files.

## Requirements
 - [Fuzzy String Match](https://github.com/kiyoka/fuzzy-string-match) requires Ruby 1.9.1 or higher.
 - [Fast-Stemmer](https://github.com/romanbsd/fast-stemmer) does not indicate which Ruby version it needs. It adds a method to the string class.
 
## To Run
In the load_iptc and load_dbp methods, switch the filenames to 'iptc.csv' and 'dbpedia.txt', respectively. The filenames currently loaded are for testing.