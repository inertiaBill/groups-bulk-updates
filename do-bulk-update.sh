#!/bin/bash

FILE_EXTRA_COMMAS_REMOVED=remove-commas.csv
FILE_MEMBER_LIST=member-list-2-bulk-upload.csv
FILE_EMAIL_ADDRESSES=welcome-mail-list.txt

usage() {
	echo ""
	echo "Usage: $0 [url_for_csv_file [last_reg_id groups email_domain header_row column_header]]"
	echo ""
	echo "  URL_for_csv_file      CSV file with field of accounts to add"
	echo "  last_reg_id           Reg ID of last person added"
	echo "  groups                Groups to which person should be added"
	echo "  email_domain          Email domain for the groups"
	echo "  header_row            Indicate last row of header"
	echo "  column_header         Name of column with account"
	echo ""
}

wait_for_input() {
	read -n1 -rsp $'Press any key to continue or Ctrl+C to exit\n'
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	usage
	echo ""
	exit 0
elif [ $# -gt 6 ]; then
	echo ""
	echo "Error: too many arguments"
	usage
	exit 1
elif [ $# -gt 1 -o $# < 7 ]; then
	echo ""
	echo "Error: wrong number of arguments"
	usage	
fi

curl -o member-list-2-bulk-upload.awk https://raw.githubusercontent.com/inertiaBill/groups-bulk-updates/master/member-list-2-bulk-upload.awk
curl -o remove-commas.awk https://raw.githubusercontent.com/inertiaBill/groups-bulk-updates/master/remove-commas.awk

echo "Download of scripts complete"
if [ -z "$1" ]; then
	exit 0;
else
	curl -o today.csv "$1" || exit 1
fi

if [ ! -z "$2" ]; then
	echo "Removing embedded commas."
	awk -f remove-commas.awk today.csv || exit 1
	echo "Generating file for bulk add."
	awk -v LAST_REG_ID=$2 -v GROUPS="$3" -v EMAIL_DOMAIN="$4" -v HEADER_ROW=$5 -v COLUMN_HEADER="$6" -f member-list-2-bulk-upload.awk "$FILE_EXTRA_COMMAS_REMOVED" || exit 1
	echo "$FILE_MEMBER_LIST ready for bulk add."
	wait_for_input
	echo ""
	rm -f $FILE_MEMBER_LIST
	rm -f $FILE_EXTRA_COMMAS_REMOVED
	echo "Copy email addresses from $FILE_EMAIL_ADDRESSES to clipboard."
	echo "  On macOS, cat welcome-mail-list.txt | pbcopy"
	echo "Send welcome email."
	wait_for_input
	rm -f $FILE_EMAIL_ADDRESSES
	rm member-list-2-bulk-upload.awk
	rm remove-commas.awk
else
	# This shouldn't happen if argument checks above were valid
	echo "Error: unknown error"
	exit 1
fi
