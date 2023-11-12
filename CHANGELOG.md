# 1.0.0.rc
* global configuration added

# 0.9.1
* fix https://github.com/alekseyl/enum_ext/issues/53 

# 0.9
* supersets works fine and same way with prefixes and suffixes as usual enum does

# 0.8.1
* Fixes issue https://github.com/alekseyl/enum_ext/issues/50
* Better describe for supersets.
* Multiple readme and comments fixes

# 0.8.0
* Methods annotations added:
  * Full descriptions: Class.enum.describe(short=true) / Class.enum.describe_short / Class.enum.describe_long / Class.enum.describe_basic
  * Per-methods: Class.enum.describe_enum_i, describe_mass_assign_enum, describe_multi_enum_scopes e.t.c.
* method Class.enum.supersets_raw added, it will return supersets decompositions to basic enum
* Class.enum.all method now returns basic enum_values + supersets_raw decomposition to basic enums ( previously was a supersets i.e. high level definition )

# 0.7.0 
* rails 7 syntax support added
* massive test process refactoring docker with both rails 7 and earlier support
* simple translate_enum allowed via `ext: [:translate_enum]`

# 0.6.0 (BREAKING CHANGES)
* fixed issue with non array superset
* standard helpers are now private, you should use enum_ext / enum , ext: []  approach to the definitions
* class.superset_statuses moved to enum_obj -> class.statuses.superset_statuses
* massive ReadMe refactoring

# 0.5.3
* refactored tests
* multi_enum_scopes will be chainable with empty params (i.e. will not change the scope)
* some development dependencies were added

# 0.5.2
* removed unused require from the upcoming version 

# 0.5.1
* gem description update

# 0.5.0
* with/without definitions will go standalone now, you need explicitly address them. Ex:
```
  multi_enum_scopes :test_type
# OR
  enum test_type: [..], ext: [:multi_enum_scopes]
```
* easier supersets definitions, no raw level class methods and multiple method call needed anymore for additive supersets:

```ruby
  ext_enum_sets :test_type, raw_level: [:unit_test, :spec]
  ext_enum_sets :test_type,
                fast: raw_level_test_types | [:controller]
# Now it could be defined like this: 
  ext_enum_sets :test_type, 
                raw_level: [:unit_test, :spec],
                fast: [:raw_level, :controller]
```
 Rem you still need couple `ext_enum_sets` calls if you want to use (`-` / `&` / `^`) array operators except for (`+` / `|`) 

* Definitions now stored as IndifferentHash just as enum originally does 
  and as an Array of strings not a symbols even if defined as ones
* Some deprecations warning added

# 0.4.6
* allows enum to enable simple helpers directly at enum definition. Ex: 
```
enum test_type: [:value], ext: [:enum_i, :mass_assign_enum]
```

# 0.4.5
* ext_enum_sets will add class method: ext_enum_pluralised, containing all extended enum sets as a single Hash

# 0.4.4
* ext_enum_sets now can be executed without 'scope' definition present on the base class, 
for instance you can now use with StoreModel's 

# 0.4.3
* ext_enum_sets now can go without options just to define with and without scopes

# 0.4.2
* bugfix for localize_enum multiple call
* test added for 0.4.1 ver funcitonality ( multiple times humanize_enum calls ) 
* all assert( a == b ) replaced with assert_equal(a,b)

# 0.4.1
* security dependency issues resolved
* activerecord version raised 
* humanize_enum could be called multiple times all definitions will be merged, i.e. there is no need to define all localizations in one place at once 