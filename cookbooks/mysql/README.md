MySQL (Percona Server)
======================

A chef recipe for managing the installed version of MySQL server and client tools on Engine Yard Cloud.
This recipe uses installs from Percona.
Includes support for installing MySQL client tools for working with RDS MySQL as well as RDS Aurora and RDS MariaDB.

Dependencies
============

- ebs - manages the attachment and formatting of EBS volumes, and physical backup scheduling
- ey-lib - provides internal stack functionality
- ey-backup - establishes logical backup scheduling
- db-ssl - generates and distributes ssl keys for database connection encryption
