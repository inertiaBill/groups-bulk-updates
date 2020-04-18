# MIT License
# 
# Copyright (c) 2020 B. Frier
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# 	 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# AWK field separation ignores double quotes. This results in
# commas within fields of CSV file looking like separators between
# fields to AWK. This script removes commas from within "quoted"
# field values to allow consistent field identification.

# Considers RFC4180
#   https://tools.ietf.org/html/rfc4180
#   Specifically about double quotes. Must be escaped by another double
#   quote.

BEGIN { 
	print "Replace embedded commas from CSV." FILENAME;
	print "Arguments:"
	for (i=0; i<ARGC; i++) {
		print "  Argument " i " is " ARGV[i];
	}
	FS=","
	#FS="\",\"|^\"|\"$"
	found_last = 0
	number_of_embedded_commas = 0
	output_file = "remove-commas.csv"
}

{
	# print "DBG --- New record ---";
	in_quotes = 0;
	string = "";

	# Only add FS before add a new CSV field to avoid changing
	# the number of fields. Don't need one before first field.
	# Hence, if (j>1) ... FS.

	# For each field in a record...
	for (j=1; j<=NF; j++) {
		# Process fields with quotes.
		# Case: Fields that start and end with double quotes.
	        # These have no commas. Just add them to resonstitued
	        # string.
		# print "DBG: field " $j;
        	if ($j ~ /^".*"$/) {
			# Complete CSV field. Print separator.
			# print "DBG: In self contained string.";
			if (j>1) string = string FS;
		        string = string $j;
			continue;
		}
		# Case: Found opening quote of sting with commas.
		# print "DBG: Before in_quotes check. Value: " in_quotes;
		if (in_quotes==1) {
			# print "DBG: in_quotes set to 1";
			# When in quotes (i.e. CSV field), don't print
		        # separator
			if ($j ~ /.*"$/) {
				# Case: Found end of CSV field.
				in_quotes=0;
				string = string $j;
			} else {
				# Case: Found another embedded comma.
				# Still within CSV field.
				number_of_embedded_commas++;
				string = string $j;
			}
			# print "DBG: Value of in_quotes: " in_quotes;
			continue;
		}
		# Case: Start of new CSV field with embedded FS
		if ($j ~ /^"/ ) {
			in_quotes=1;
			number_of_embedded_commas++;
			# print "DBG: Found start of quotation with comma. Value: " in_quotes;
		}
		# The following handles string update for the previous
	        # case as well as case of simple CSV field with no quotes.
		if (j>1) string = string FS;
		string = string $j;
        }
	# print "DBG: " string;
	print string > output_file;
}

END {
	print "Embedded commas found: " number_of_embedded_commas;
	print "Updated file written to: " output_file
	print "Deleting " FILENAME;
	system( "rm " FILENAME);
}
