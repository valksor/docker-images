#!/usr/bin/env bash

set -eux

# https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux
# Modified for flexible full backups based on FULL_BACKUP_LIST

###########################
####### LOAD CONFIG #######
###########################

CONFIG_FILE_PATH=""
while [[ $# -gt 0 ]]; do
	case "$1" in
		-c)
			CONFIG_FILE_PATH="$2"
			shift 2
			;;
		*)
			echo "Unknown option: '$1'" >&2
			exit 1
			;;
	esac
done

# Determine config file path
if [[ -n "$CONFIG_FILE_PATH" ]]; then  # -c option was provided
	if [[ ! -f "$CONFIG_FILE_PATH" ]]; then
		echo "Error: Config file specified with -c not found: $CONFIG_FILE_PATH" >&2
		exit 1
	fi
else  # Use default config file in current directory
	SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
	CONFIG_FILE_PATH="${SCRIPTPATH}/pg_backup.config"

	if [[ ! -f "$CONFIG_FILE_PATH" ]]; then
		echo "Error: Default config file not found: $CONFIG_FILE_PATH" >&2
		exit 1
	fi
fi

source "$CONFIG_FILE_PATH"

export PGPASSWORD=$POSTGRES_PASSWORD

###########################
#### PRE-BACKUP CHECKS ####
###########################

# Make sure we're running as the required backup user
if [[ -n "$BACKUP_USER" ]] && [[ "$(id -un)" != "$BACKUP_USER" ]]; then
	echo "This script must be run as $BACKUP_USER. Exiting." >&2
	exit 1
fi

###########################
### INITIALISE DEFAULTS ###
###########################

HOSTNAME="${HOSTNAME:-localhost}"
USERNAME="${USERNAME:-postgres}"

###########################
#### START THE BACKUPS ####
###########################

perform_backups() {
	SUFFIX="$1"
	FINAL_BACKUP_DIR="$BACKUP_DIR$(date +\%Y-\%m-\%d)$SUFFIX/"

	echo "Making backup directory in $FINAL_BACKUP_DIR"

	if ! mkdir -p "$FINAL_BACKUP_DIR"; then
		echo "Cannot create backup directory in $FINAL_BACKUP_DIR. Go and fix it!" >&2
		exit 1
	fi

	#######################
	### GLOBALS BACKUPS ###
	#######################

	echo -e "\n\nPerforming globals backup"
	echo -e "--------------------------------------------\n"

	if [[ "$ENABLE_GLOBALS_BACKUPS" = "yes" ]]; then
		echo "Globals backup"

		set -o pipefail
		if ! pg_dumpall -g -h "$HOSTNAME" -U "$USERNAME" <<< "$POSTGRES_PASSWORD" | gzip > "$FINAL_BACKUP_DIR"globals.sql.gz.in_progress; then
			echo "[!!ERROR!!] Failed to produce globals backup" >&2
		else
			mv "$FINAL_BACKUP_DIR"globals.sql.gz.in_progress "$FINAL_BACKUP_DIR"globals.sql.gz
		fi
		set +o pipefail
	else
		echo "None"
	fi

	###########################
	###### FULL BACKUPS #######
	###########################

	echo -e "\n\nPerforming full backups"
	echo -e "--------------------------------------------\n"

	echo "FULL_BACKUP_LIST before if: $FULL_BACKUP_LIST"  # Debug line

	if [[ -z "$FULL_BACKUP_LIST" ]]; then	 # Check if FULL_BACKUP_LIST is empty or unset
		echo "Backing up all databases (FULL_BACKUP_LIST is empty or unset)"  # Debug line
		FULL_BACKUP_QUERY="SELECT datname FROM pg_database WHERE NOT datistemplate AND datallowconn;"
		for DATABASE in $(psql -h "$HOSTNAME" -U "$USERNAME" -At -c "$FULL_BACKUP_QUERY" postgres); do
			echo "Full backup of $DATABASE"

			set -o pipefail
			if ! pg_dump -Fp -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" <<< "$POSTGRES_PASSWORD" | gzip > "$FINAL_BACKUP_DIR$DATABASE.sql.gz.in_progress"; then
				echo "[!!ERROR!!] Failed to produce plain backup database $DATABASE" >&2
			else
				mv "$FINAL_BACKUP_DIR$DATABASE.sql.gz.in_progress" "$FINAL_BACKUP_DIR$DATABASE.sql.gz"
			fi
			set +o pipefail
		done
	else  # FULL_BACKUP_LIST is set, backup only specified databases
		echo "Backing up specific databases: $FULL_BACKUP_LIST"  # Debug line
		FULL_BACKUP_LIST=${FULL_BACKUP_LIST//,/ } # Remove commas for looping
		for DATABASE in $FULL_BACKUP_LIST; do
			echo "Full backup of $DATABASE"

			set -o pipefail
			if ! pg_dump -Fp -h "$HOSTNAME" -U "$USERNAME" "$DATABASE" <<< "$POSTGRES_PASSWORD" | gzip > "$FINAL_BACKUP_DIR$DATABASE.sql.gz.in_progress"; then
				echo "[!!ERROR!!] Failed to produce plain backup database $DATABASE" >&2
			else
				mv "$FINAL_BACKUP_DIR$DATABASE.sql.gz.in_progress" "$FINAL_BACKUP_DIR$DATABASE.sql.gz"
			fi
			set +o pipefail
		done
	fi

	echo -e "\nAll database backups complete!"
}


# MONTHLY BACKUPS
DAY_OF_MONTH=$(date +%d)

if [[ "$DAY_OF_MONTH" -eq 1 ]]; then
	# Delete all expired monthly directories
	find "$BACKUP_DIR" -maxdepth 1 -name "*-monthly" -exec rm -rf '{}' +

	perform_backups "-monthly"

	exit 0
fi

# WEEKLY BACKUPS

DAY_OF_WEEK=$(date +%u) # 1-7 (Monday-Sunday)
EXPIRED_DAYS=$((($WEEKS_TO_KEEP * 7) + 1))

if [[ "$DAY_OF_WEEK" == "$DAY_OF_WEEK_TO_KEEP" ]]; then  # Use == for string comparison within [[ ]]
	# Delete all expired weekly directories
	find "$BACKUP_DIR" -maxdepth 1 -mtime +"$EXPIRED_DAYS" -name "*-weekly" -exec rm -rf '{}' +

	perform_backups "-weekly"

	exit 0
fi


# DAILY BACKUPS

# Delete daily backups 7 days old or more
find "$BACKUP_DIR" -maxdepth 1 -mtime +"$DAYS_TO_KEEP" -name "*-daily" -exec rm -rf '{}' +

perform_backups "-daily"
