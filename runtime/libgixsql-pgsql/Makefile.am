lib_LTLIBRARIES = libgixsql-pgsql.la
libgixsql_pgsql_la_SOURCES =\
  DbInterfaceManagerPGSQL.cpp\
  DbInterfacePGSQL.cpp\
  dblib.cpp\
  utils.cpp\
  DbInterfacePGSQL.h\
  utils.h

libgixsql_pgsql_la_CXXFLAGS =\
  $(LIBPQ_CFLAGS)\
  -I$(top_srcdir)/common\
  -I$(top_srcdir)/runtime/libgixsql\
  -I$(top_srcdir)/common\
  -std=c++17\
  -DNDEBUG\
  -DSPDLOG_COMPILED_LIB\
  -DSPDLOG_FMT_EXTERNAL

libgixsql_pgsql_la_LIBADD = $(SPDLOG_LIBS) $(LIBPQ_LIBS)
libgixsql_pgsql_la_LDFLAGS = -no-undefined -avoid-version


