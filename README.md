### clone_ldap_backed_mysql_user.sh

The `clone_ldap_backed_mysql_user.sh` script is a Bash script that allows you to clone an LDAP-backed MySQL user. It creates a new MySQL user based on an existing user, transfers the grants from the existing user to the new user, and records the cloning activity in the audit table.

### Usage

```bash
bash clone_ldap_backed_mysql_user.sh <existing_user> <new_user> <new_ldap_dn> <dbadmin_user>
```

### Arguments

- `existing_user`: The existing user to be cloned.
- `new_user`: The name of the new user to be created.
- `new_ldap_dn`: The LDAP DN value for the new user.
- `dbadmin_user`: The MySQL admin user.

### Prerequisites

- MySQL server with appropriate privileges.
- MySQL password for the `dbadmin_user`.

### Dependencies

- MySQL client command-line tool.

### Functionality

1. The script prompts for the MySQL password to establish a connection with the MySQL server.
2. It sets an environment variable to enable clear text authentication.
3. It creates an audit table if it doesn't already exist in the MySQL server.
4. It retrieves all the hosts tied to the existing user.
5. For each host, it performs the following steps:
   - Drops the new user if it already exists.
   - Creates the new user with the specified LDAP DN value.
   - Fetches the grants for the existing user on the current host.
   - Replaces the existing user with the new user in the grants.
   - Executes the grants for the new user on the current host.
6. It records the cloning activity in the audit table, including the existing user, new user, LDAP DN, cloning timestamp, and the user who performed the cloning.
7. If any step fails, the script exits with a non-zero status code.

### Example

```bash
bash clone_ldap_backed_mysql_user.sh existing_user new_user "cn=new_user,ou=users,dc=example,dc=com" dbadmin_user
```

This example clones the `existing_user` to create a new user named `new_user` with the LDAP DN "cn=new_user,ou=users,dc=example,dc=com". The script assumes that the MySQL admin user is `dbadmin_user` and will prompt for the MySQL password.

### Notes

- This script assumes that the MySQL server is running on the local machine.
- The script uses the `mysql` command-line tool to interact with the MySQL server. Make sure it is installed and accessible in the system's `PATH`.
- The script sets the `LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN` environment variable to enable clear text authentication. This is required for authentication with LDAP.
- Ensure that the MySQL user specified as `dbadmin_user` has the necessary privileges to create users and modify grants.

### License

This script is released under the [MIT License](LICENSE).

**Please note that the script provided is a template and may need to be customized to fit your specific environment and requirements.
Make sure to review and test the script thoroughly before using it in a production environment.
Please note that this script assumes you have the necessary permissions and dependencies (such as the MySQL client command-line tool) installed.
Makesure to review and customize the script as per your specific environment and requirements.**
