if node.engineyard.environment['db_stack_name'] =~ /postgres/
  postgres_version = node['postgresql']['short_version']
else
  postgres_version = "10"
end

package "postgresql-server-dev-#{postgres_version}"
package "libmysqlclient-dev"
package "libsqlite3-dev"
