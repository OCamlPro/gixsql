#!/bin/env bash
set -o errexit
set -o nounset
set -o pipefail

# Default configuration
BUILD_DIR=${BUILD_DIR:=./_build}
INSTALL_DIR=${INSTALL_DIR:=install}

POSTGRE_HOST=${POSTGRE_HOST:=localhost}
POSTGRE_PORT=${POSTGRE_PORT:=5432}
POSTGRE_USER=${POSTGRE_USER:=test}
POSTGRE_PWD=${POSTGRE_PWD:=test}
POSTGRE_DB1=${POSTGRE_DB1:=testdb1}
POSTGRE_DB2=${POSTGRE_DB2:=testdb2}

TEST_VERBOSITY=${TEST_VERBOSITY:=0}
TEST_DIR=${TEST_DIR:=/tmp/gixsql-test}
export GIXTEST_LOCAL_CONFIG="$TEST_DIR/config.xml"

INSTALL_PATH="$PWD/$BUILD_DIR/$INSTALL_DIR"

# Build and locally install the project
if [ ! -f "./extra_files.mk" ]; then
  touch "extra_files.mk"
fi

if [ ! -d "$BUILD_DIR" ]; then
  mkdir "$BUILD_DIR"
  echo "Create directory $BUILD_DIR"
fi

echo "Compiling gixsql..."
cd $BUILD_DIR

if [ ! -d "$INSTALL_DIR" ]; then
  mkdir "$INSTALL_DIR"
  echo "Install gixsql in $INSTALL_PATH"
fi

../configure --prefix="$INSTALL_PATH" > /dev/null
make -j 8 > /dev/null
make install > /dev/null
cd ..

echo "Preparing tests..."
if [ -d "$TEST_DIR" ]; then
  while true; do
      read -p "We need to erase the directory $TEST_DIR. Remove it? " yn
      case $yn in
          [Yy]* ) rm -Rf $TEST_DIR; break;;
          [Nn]* ) exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
fi

mkdir "$TEST_DIR"

# Output the configuration file for the runner
cat <<EOF >> $TEST_DIR/config.xml
<?xml version="1.0" encoding="utf-8" ?>
<test-local-config>

	<global>
    <gixsql-install-base>$INSTALL_PATH</gixsql-install-base>
		<keep-temps>1</keep-temps>
		<verbose>$TEST_VERBOSITY</verbose>
		<test-filter></test-filter>
		<dbtype-filter>pgsql</dbtype-filter>
    <mem-check></mem-check>
		<temp-dir>$TEST_DIR</temp-dir>
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
			<config_dir_path>$GNUCOBOL_SHARE/gnucobol/config</config_dir_path>
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
			<port>$POSTGRE_PORT</port>
			<dbname>$POSTGRE_DB1</dbname>
			<username>$POSTGRE_USER</username>
			<password>$POSTGRE_PWD</password>
			<options>native_cursors=off</options>
		</data-source>
		<data-source type="pgsql" index="2">
      <hostname>localhost</hostname>
      <type>pgsql</type>
			<port>$POSTGRE_PORT</port>
			<dbname>$POSTGRE_DB2</dbname>
			<username>$POSTGRE_USER</username>
			<password>$POSTGRE_PWD</password>
			<options>native_cursors=off</options>
		</data-source>
	</data-sources>
</test-local-config>
EOF

echo "Building runner..."
# We have to rebuild the test runner because it includes test files...
dotnet build "gixsql-tests-nunit/gixsql-tests-nunit.csproj" > /dev/null

# Start the runner
dotnet "gixsql-tests-nunit/bin/Debug/net6.0/gixsql-tests-nunit.dll"

echo "Results of the tests can found in $TEST_DIR"
