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