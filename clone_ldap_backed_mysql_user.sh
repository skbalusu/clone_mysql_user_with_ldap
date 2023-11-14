#!/bin/bash

######################################################################
# clone_ldap_backed_mysql_user.sh
#
# Description:
#   This script clones an LDAP-backed MySQL user. It creates a new MySQL user based on an existing user,
#   transfers the grants from the existing user to the new user, and records the cloning activity in the audit table.
#
# Usage:
#   bash clone_ldap_backed_mysql_user.sh <existing_user> <new_user> <new_ldap_dn> <dbadmin_user>
#
# Arguments:
#   - existing_user: The existing user to be cloned.
#   - new_user: The name of the new user to be created.
#   - new_ldap_dn: The LDAP DN value for the new user.
#   - dbadmin_user: The MySQL admin user.
#
# Prerequisites:
#   - MySQL server with appropriate privileges.
#   - MySQL password for the dbadmin_user.
#
# Dependencies:
#   - MySQL client command-line tool.
#
# Author:
#   Santhi Balusu
#
# Date:
#   14/NOV/2023
######################################################################

# Print a line of characters
print_line() {
    local line="$1"
    local length=${#line}
    for ((i=0; i<length; i++)); do
        echo -n "${line:i:1}"
    done
    echo
}

# Store the provided arguments in variables
existing_user="$1" # Mirror User
new_user="$2" # New user that needs creating
new_ldap_dn="$3" # LDAP DN value for the new user
dbadmin_user="$4" # MySQL admin user

# Prompt for the MySQL password
echo -n "Enter the MySQL password: "
read -s mysql_password
echo

# Set environment variable to enable clear text authentication
export LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN=1

# Create audit table if it doesn't exist
audit_table_query="use mysql;CREATE TABLE IF NOT EXISTS ldap_user_clone_audit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    existing_user VARCHAR(100) NOT NULL,
    new_user VARCHAR(100) NOT NULL,
    new_ldap_dn VARCHAR(255) NOT NULL,
    cloning_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cloning_user VARCHAR(100) NOT NULL
);"

mysql -u "$dbadmin_user" -p"$mysql_password" -e "$audit_table_query" 2>/dev/null

# Get the hosts tied to the existing user
echo "Getting all the hosts tied to ${existing_user}"
hosts_query="SELECT DISTINCT Host FROM mysql.user WHERE User = '$existing_user';"
hosts=$(mysql -u "$dbadmin_user" -p"$mysql_password" -N -B -e "$hosts_query")
echo "Hosts tied down to ${existing_user}:"
echo "${hosts}"

# Iterate over each host
for host in $hosts; do
    echo
    echo "Creating ${new_user}@${host} with same permissions as ${existing_user}@${host}"

    # Drop the new user if it already exists
    echo "Dropping ${new_user}@${host} if it already exists..."
    drop_user_query="DROP USER IF EXISTS '$new_user'@'$host';"
    mysql -u "$dbadmin_user" -p"$mysql_password" -e "$drop_user_query" 2>/dev/null

    # Create the new user with the specified LDAP DN value
    echo "Creating ${new_user}@${host} with DN value set to ${new_ldap_dn}"
    create_user_query="CREATE USER '$new_user'@'$host' IDENTIFIED WITH authentication_ldap_simple AS '$new_ldap_dn';"
    mysql -u "$dbadmin_user" -p"$mysql_password" -e "$create_user_query" 2>/dev/null

    # Fetch the grants for the existing user on the current host
    echo "Fetching Grants for ${existing_user}@${host}"
    grants_query="SHOW GRANTS FOR '$existing_user'@'$host';"
    grants=$(mysql -u "$dbadmin_user" -p"$mysql_password" -N -B -e "$grants_query" 2>/dev/null)
    echo "${existing_user} Grants:-"
    echo "${grants}"

    # Replace the existing user with the new user in the grants
    echo "Replacing ${existing_user}@${host} with ${new_user}@${host} in Grants"
    new_grants=$(echo "$grants" | sed "s/'$existing_user'@'/$new_user'@'/")

    # Display the grants for the new user
    echo
    echo "Grants for $new_user tied to $host:"
    echo "$new_grants"

    # Execute the grants for the new user on the current host
    if [[ -n "$new_grants" ]]; then
        echo
        mysql -u "$dbadmin_user" -p"$mysql_password" -e "$new_grants" 2>/dev/null
    else
        echo
        echo "No privileges found for $existing_user on $host. Skipping grant step."
    fi

    # Record the cloning activity in the audit table
    audit_insert_query="INSERT INTO mysql.ldap_user_clone_audit (existing_user, new_user, new_ldap_dn, cloning_user) VALUES ('$existing_user', '$new_user', '$new_ldap_dn', '$USER');"
    mysql -u "$dbadmin_user" -p"$mysql_password" -e "$audit_insert_query" 2>/dev/null
done

# Unset the environment variable
unset LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN

echo
print_line "Cloning complete!"
