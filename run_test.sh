#!/bin/env sh
set -eu

# Default configuration
INSTALL_DIR="$PWD/_install"
OUTPUT_DIR="$PWD/_output"

finalizer () {
  # Ensure that we try to stop the server even if the script failed
  if [ -d "$OUTPUT_DIR" ]; then
    cat "$OUTPUT_DIR/pg.log" || true
    echo "Stop PostgreSQL server"
    pg_ctl -D "$PG_DIR" stop || true
    rm -rf "$OUTPUT_DIR"
  fi
}

trap "finalizer" EXIT

# These parameters are exported for PostgreSQL tools
export PGHOST="${POSTGRE_HOST:=localhost}"
export PGPORT="${POSTGRE_PORT:=6666}"
export PGUSER="${POSTGRE_USER:=test}"
export PGPASSWORD="${PGPASSWORD:=test}"

PGDB1=${POSTGRE_DB1:=testdb1}
PGDB2=${POSTGRE_DB2:=testdb2}
TEST_VERBOSITY=${TEST_VERBOSITY:=0}

# These parameters are exported for the test runner
export GIXTEST_LOCAL_CONFIG="$OUTPUT_DIR/config.xml"

INSTALL_PATH="$PWD/$INSTALL_DIR"
PG_DIR="$OUTPUT_DIR/pg"

finalizer
mkdir "$OUTPUT_DIR"

# Configure and start PostgreSQL
echo "test" >> "$OUTPUT_DIR/pg_password"
initdb -U "$PGUSER" -D "$PG_DIR" \
  --pwfile="$OUTPUT_DIR/pg_password"

cat <<EOF >> "$PG_DIR/postgresql.conf"
listen_addresses = '$PGHOST'
unix_socket_directories = '.'
port = $PGPORT
EOF

pg_ctl -D "$PG_DIR" -l "$OUTPUT_DIR/pg.log" start
createdb "$PGDB1"
createdb "$PGDB2"

# Build and locally install the project
if [ ! -f "./extra_files.mk" ]; then
  touch "extra_files.mk"
fi

echo "Compiling gixsql..."

if [ ! -d "$INSTALL_DIR" ]; then
  mkdir "$INSTALL_DIR"
  echo "Install gixsql in $INSTALL_PATH"
fi

autoreconf -if
./configure --prefix="$INSTALL_PATH" --disable-mysql \
  --disable-odbc --disable-sqlite --disable-oracle
make -j 8
make install

echo "Preparing tests..."

# Output the configuration file for the runner
cat <<EOF >> "$OUTPUT_DIR/config.xml"
<?xml version="1.0" encoding="utf-8" ?>
<test-local-config>

	<global>
    <gixsql-install-base>$INSTALL_PATH</gixsql-install-base>
		<keep-temps>1</keep-temps>
		<verbose>$TEST_VERBOSITY</verbose>
		<test-filter></test-filter>
		<dbtype-filter>pgsql</dbtype-filter>
    <mem-check></mem-check>
		<temp-dir>$OUTPUT_DIR</temp-dir>
		<environment>
			<variable key="GIXSQL_FIXUP_PARAMS" value="on" />
		</environment>
	</global>

	<architectures>
		<architecture id="x64" />
	</architectures>
	<compiler-types>
		<compiler-type id="gcc" />
	</compiler-types>

	<compilers>
		<compiler type="gcc" architecture="x64" id="gnucobol-3.1.2-linux-gcc-x64">
      <bin_dir_path>$GNUCOBOL_BIN</bin_dir_path>
      <lib_dir_path>$GNUCOBOL_LIB</lib_dir_path>
			<environment>
			</environment>
		</compiler>
	</compilers>

	<data-source-clients>
		<data-source-client type="pgsql" architecture="x64">
			<environment>
			</environment>
			<provider value="Npgsql" />
		</data-source-client>
	</data-source-clients>

	<data-sources>
		<data-source type="pgsql" index="1">
      <hostname>localhost</hostname>
      <type>pgsql</type>
			<port>$PGPORT</port>
			<dbname>$PGDB1</dbname>
			<username>$PGUSER</username>
			<password>$PGPASSWORD</password>
			<options>native_cursors=off</options>
		</data-source>
		<data-source type="pgsql" index="2">
      <hostname>localhost</hostname>
      <type>pgsql</type>
			<port>$PGPORT</port>
			<dbname>$PGDB2</dbname>
			<username>$PGUSER</username>
			<password>$PGPASSWORD</password>
			<options>native_cursors=off</options>
		</data-source>
	</data-sources>
</test-local-config>
EOF

echo "Building runner..."
# We have to rebuild the test runner because it includes test files...
dotnet build "gixsql-tests-nunit/gixsql-tests-nunit.csproj"

# Start the runner
dotnet "gixsql-tests-nunit/bin/Debug/net6.0/gixsql-tests-nunit.dll"
