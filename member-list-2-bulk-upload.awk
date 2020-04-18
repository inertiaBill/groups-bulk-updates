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

# This script takes a CSV, determines the Google account email column,
# and creates a bulk upload CSV file from them.
#
# This script is intended to work with a wide range of AWK versions.
# As such, it does not depend on features of newer versions. 

function number_of_elements(input_array)
{
	num = 0;
	for (key in input_array) {
		num++;
	}
	return num;
}

BEGIN { 
	print "Starting to process..."
	print "Arguments:"
	for (i=0; i<ARGC; i++) {
		print "  Argument " i " is " ARGV[i];
	}
	FS=","
	#RS=/\r\n/
	#FS="\",\"|^\"|\"$"
	found_last = 0
	number_added = 0
	number_skipped = 0
	current_reg_id = 0
	total_members = 0
	output_file = "member-list-2-bulk-upload.csv"
	welcome_mail_list_output_file = "welcome-mail-list.txt"
	print "Last registration ID: " LAST_REG_ID
	print "Group Email [Required],Member Email,Member Type,Member Role" >output_file
}

BEGIN {
	number_of_groups = split(GROUPS, groups_array, /,/);
	print "Array using 'in',";
	for (g in groups_array) {
		print groups_array[g];
	}
	print "Array using 'for',";
	for (h=1; h<=number_of_elements(groups_array); h++) {
		print groups_array[h];
	}
}	

# Need this to ignore the recently added cruft at bottom of report.
# If we encounter a line after the header that doesn't contain a number
# then we are done processing this file.
#
# Could not simply look for blank lines because they weren't actually
# blank. Apparent blank lines actually had non-printable characters
# that did not seem to have searchable equivalents.

{ if (NR > HEADER_ROW) {
	if ($0 !~ /[0-9]+/) {
		print "End of member records";
		# Done with regular records. Stop processing and jump
	        # to END blocks.
		exit;
  	} else {
  		total_members += 1;
  	}
}
}

{ if (NR == HEADER_ROW) {
	print "Looking for column " COLUMN_HEADER;
	for (i=1; i<=NF; i++) {
        	if ($i==COLUMN_HEADER) {
                	google_account_column=i;
                        print $i " found at column " google_account_column;
                }
        }
}
}

# Checking for last member added.
{ if ($1 == LAST_REG_ID) {
	# When we've found the last member added, raise flag
	found_last=1;
	print $6 " " $7 " " $1 " matches Reg ID: " LAST_REG_ID;
	# Skip this recorded since this member was added last time
	next;
}
}


# If we haven't found the last member added, skip to the next
# record.
{ if (found_last == 0) next; }

# Add the member to output file in expected format
#
# Nongreedy regular expressions don't see to work as expected
# on some versions of awk. As such, we need to preprocess the
# CSV file to remove commas within fields.
# 
# Keeping following here in case we switch to a version where
# this is supported as this would be much simplier.
#{ gsub(",\".*?\",", ",Replaced quoted value,") }
#{ gsub("\".*?\"", ",replaced_quoted_value,") }
#{ gsub(/".*?"/,"replaced_quoted_value") }
#{ print "After: " $0 }
#{ print $COLUMN_NUMBER }
{ if ($google_account_column != "") {
	number_added += 1;
	print "";
	print "Adding " $6 " " $8 " " $google_account_column;
	print "  DBG \n" $0;
	for (h=1; h<=number_of_elements(groups_array); h++) {
		print groups_array[h] "@" EMAIL_DOMAIN "," $google_account_column ",USER,MEMBER" >>output_file;
	}
	print $google_account_column >>welcome_mail_list_output_file;
} else {
	number_skipped += 1;
	print "";
	print "Reject " $6 " " $8 " because Google account appeared as " $google_account_column;
	print "  DBG \n" $0
}
current_reg_id = $1;
}

END {
	print "";
	print "Updated file written to: " output_file;
	print "Number added to file: " number_added;
	print "Number skipped: " number_skipped;
	print "Total number of members in report: " total_members;
	print "";
	print "Deleting " FILENAME;
	system( "rm " FILENAME);
	print "";
	print "Tasks to complete";
	print "  In preparation for next time update the LAST_REG_ID value to: " current_reg_id; 
	print "  Do bulk add";
	print "  Delete the bulk update file: " output_file;
	print "  Send welcome message";
	print "  Delete welcome message recipient list file: " welcome_mail_list_output_file;
	print "";
}
