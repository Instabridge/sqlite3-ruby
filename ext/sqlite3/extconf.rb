ENV['RC_ARCHS'] = '' if RUBY_PLATFORM =~ /darwin/

require 'mkmf'

# :stopdoc:

RbConfig::MAKEFILE_CONFIG['CC'] = ENV['CC'] if ENV['CC']

ldflags = cppflags = nil
if RbConfig::CONFIG["host_os"] =~ /darwin/
  begin
    if with_config('sqlcipher')
      brew_prefix = `brew --prefix sqlcipher`.chomp
      ldflags   = "#{brew_prefix}/lib"
      cppflags  = "#{brew_prefix}/include/sqlcipher"
      pkg_conf  = "#{brew_prefix}/lib/pkgconfig"
    else
      brew_prefix = `brew --prefix sqlite3`.chomp
      ldflags   = "#{brew_prefix}/lib"
      cppflags  = "#{brew_prefix}/include"
      pkg_conf  = "#{brew_prefix}/lib/pkgconfig"
    end

    # pkg_config should be less error prone than parsing compiler
    # commandline options, but we need to set default ldflags and cpp flags
    # in case the user doesn't have pkg-config installed
    ENV['PKG_CONFIG_PATH'] ||= pkg_conf
  rescue
  end
end

have_library 'dl' # for static builds

if with_config('sqlcipher')
  pkg_config("sqlcipher")
else
  pkg_config("sqlite3")
end

# --with-sqlite3-{dir,include,lib}
if with_config('sqlcipher')
  $CFLAGS << ' -DUSING_SQLCIPHER'
  dir_config("sqlcipher", cppflags, ldflags)
else
  dir_config("sqlite3", cppflags, ldflags)
end

if RbConfig::CONFIG["host_os"] =~ /mswin/
  $CFLAGS << ' -W3'
end

if RUBY_VERSION < '2.7'
  $CFLAGS << ' -DTAINTING_SUPPORT'
end

# enable column metadata
$CFLAGS << ' -DSQLITE_ENABLE_COLUMN_METADATA=1'

# Functions defined in 1.9 but not 1.8
have_func('rb_proc_arity')

# Functions defined in 2.1 but not 2.0
have_func('rb_integer_pack')

# These functions may not be defined
have_func('sqlite3_initialize')
have_func('sqlite3_backup_init')
have_func('sqlite3_column_database_name')
have_func('sqlite3_enable_load_extension')
have_func('sqlite3_load_extension')
have_func('sqlite3_open_v2')



have_func('sqlite3_prepare_v2')
have_type('sqlite3_int64', 'sqlite3.h')
have_type('sqlite3_uint64', 'sqlite3.h')

create_makefile('sqlite3/sqlite3_native')
