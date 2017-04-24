# EnumExt

EnumExt extends rails enum with localization/translation and it's helpers, mass-assign on scopes with bang, advanced sets logic over existing enum.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'enum_ext', '~> 0.3'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install enum_ext

## Usage
 To use enum extension extend main model class with EnumExt module, and extend enum the way you need:
 
    class SomeModel
      extend EnumExt
      
      enum_i ...
      humanize_enum ...
      translate_enum ...
      ext_enum_sets ...
      mass_assign_enum ...
    end
 
 Let's assume that we have model Request representing some buying requests with enum **status**, and we have model Order with requests, 
 representing single purchase, like this:

     class Request
       extend EnumExt
       belongs_to :order
       enum status: [ :in_cart, :waiting_for_payment, :paid, :ready_for_shipment, :on_delivery, :delivered ]
     end

     class Order
       has_many :requests
     end

 Now let's review some examples of possible enum extensions

### Humanization (humanize_enum) 
  
  if app doesn't need internationalization, it may use humanize_enum to make enum user friendly

  ```  
  humanize_enum :status, {
      #locale dependent example with pluralization and lambda:
      in_cart: -> (t_self) { I18n.t("request.status.in_cart", count: t_self.sum ) }
  
      #locale dependent example with pluralization and proc:
      paid: Proc.new{ I18n.t("request.status.paid", count: self.sum ) }
  
      #locale independent:
      ready_for_shipment: "Ready to go!"
    }
  end
  ```  
   
  This call adds to instance:
   - t_in_cart, t_paid, t_ready_for_shipment
  
  adds to class:
   - t_statuses - as given or generated values
   - t_statuses_options - translated enum values options for select input
   - t_statuses_options_i - same as above but use int values with translations works for ActiveAdmin filters for instance

  
  Example with block:

  ```
  humanize_enum :status do
   I18n.t("scope.#{status}")
  end
  ```
  
  Example for select:
  
  ```
    f.select :status, Request.t_statuses_options
  ```
  
  in Active Admin filters
  ```
    filter :status, as: :select, label: 'Status', collection: Request.t_statuses_options_i
  ```
 
  
  Rem: select options may break when using lambda() or proc with instance method, but will survive with block
  
  Console:
  ```
    request.sum = 3
    request.paid!
    request.status     # >> paid
    request.t_status   # >> "paid 3 dollars"
    Request.t_statuses # >> { in_cart: -> { I18n.t("request.status.in_cart") }, ....  }
  ```  
    
### Translate (translate_enum) 

Enum is translated using scope 'active_record.attributes.class_name_underscore.enum_plural', or the given one:

       translate_enum :status, 'active_record.request.enum'

Or it can be done with block either with translate or humanize:
        
       translate_enum :status do 
         I18n.t( "active_record.request.enum.#{status}" )
       end

### Enum to_i shortcut ( enum_i )

Defines method enum_name_i shortcut for Model.enum_names[elem.enum_name]

**Ex** 
  enum_i :status
  ...
  request.paid_i # 10
  

### Enum Sets (ext_enum_sets)
 
 **Use-case** For example you have pay bills of different types, and you want to group some types in debit and credit "super-types", 
 and have scope PayBill.debit, instance method with question mark as usual enum does pay_bill.debit?.
 
 You can do this with method **ext_enum_sets** it creates:  scopes for subsets, instance method with ? and some class methods helpers
   
   For this call:
   ```
     ext_enum_sets :status, {
                     delivery_set: [:ready_for_shipment, :on_delivery, :delivered] # for shipping department for example
                     in_warehouse: [:ready_for_shipment]  # this just for superposition example  below
                   }
   ```
it will generate:
```
instance:
    - methods: delivery_set?, in_warehouse?

class:
    - named scopes: delivery_set, in_warehouse
    - parametrized scopes: with_statuses, without_statuses
    class helpers:
        - delivery_set_statuses (=[:ready_for_shipment, :on_delivery, :delivered] ), in_warehouse_statuses
        - delivery_set_statuses_i (= [3,4,5]), in_warehouse_statuses_i (=[3])

     class translation helpers ( started with t_... ):
        - t_delivery_set_statuses_options (= [['translation or humanization', :ready_for_shipment] ...] ) for select inputs purposes
        - t_delivery_set_statuses_options_i (= [['translation or humanization', 3] ...]) same as above but with integer as value ( for example to use in Active admin filters )
```

 ```
   Console:
    request.on_delivery!
    request.delivery_set?                    # >> true
 
    Request.delivery_set.exists?(request)    # >> true
    Request.in_warehouse.exists?(request)    # >> false
   
    Request.delivery_set_statuses            # >> [:ready_for_shipment, :on_delivery, :delivered]
   
    Request.with_statuses( :payed, :delivery_set )    # >> :payed and [:ready_for_shipment, :on_delivery, :delivered] requests
    Request.without_statuses( :payed )                # >> scope for all requests with statuses not eq to :payed
    Request.without_statuses( :payed, :in_warehouse ) # >> scope all requests with statuses not eq to :payed or :ready_for_shipment
 ```  
 
   Rem:
    ext_enum_sets can be called twice defining a superposition of already defined sets ( considering previous example ):
    
```
    ext_enum_sets :status, {
                outside_wharehouse: ( delivery_set_statuses - in_warehouse_statuses )... any other array operations like &, + and so can be used
              }
```

 
### Mass-assign ( mass_assign_enum )
 
 Syntax sugar for mass-assigning enum values. 
 
 **Use-case:** it's often case when I need bulk update without callbacks, so it's gets frustrating to repeat: 
 ```
    some_scope.update_all(status: Request.statuses[:new_status], update_at: Time.now)
 ```
 If you need callbacks you can do like this: some_scope.each(&:new_stat!) but if you don't need callbacks and you 
 has hundreds and thousands of records to change at once you need update_all

 ```
    mass_assign_enum( :status )
 ```

 Console:

```
    request1.in_cart!
    request2.waiting_for_payment!
    Request.non_paid.paid!
    request1.paid?                         # >> true
    request2.paid?                         # >> true
    request1.updated_at                     # >> ~ Time.now
    
    order.requests.already_paid.count          # >> N
    order.requests.delivered.count              # >> M
    order.requests.already_paid.delivered!
    order.requests.already_paid.count          # >> 0
    order.requests.delivered.count              # >> N + M
```

## Tests
   rake test
 
## Development


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alekseyl/enum_ext or by email: leshchuk@gmail.com


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

### Thanks

Thanks for the star vzamanillo, it inspires me to do mass refactor and gracefully cover code in this gem by tests.
