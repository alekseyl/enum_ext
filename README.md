# EnumExt

EnumExt extends rails enum adding localization template, mass-assign on scopes with bang and some sets logic over existing enum.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'enum_ext'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install enum_ext

## Usage
 To use enum extension extend main model class with EnumExt module, and extend enum the way you need:
 
    class SomeModel
      extend EnumExt
      
      localize_enum ...
      ext_enum_sets ...
      mass_assign_enum ...
    end
 
 Let's assume that we have model Request representing some buying requests with enum **status**, and we have model Order with requests, representing single purchase, like this:

     class Request
       extend EnumExt
       belongs_to :order
       enum status: [ :in_cart, :waiting_for_payment, :payed, :ready_for_shipment, :on_delivery, :delivered ]
     end

     class Order
       has_many :requests
     end

 Now let's review some examples of possible enum extensions

### Localization (localize_enum) 
  
     class Request
      ...
      localize_enum :status, {
    
         #locale dependent example ( it dynamically use current locale ):
         in_cart: -> { I18n.t("request.status.in_cart") },
    
         #locale dependent example with internal pluralization and lambda:
         payed: -> (t_self) { I18n.t("request.status.payed", count: t_self.sum ) }
        
         #locale dependent example with internal pluralization and proc:
         payed: proc { I18n.t("request.status.payed", count: sum ) }
        
         #locale independent:
         ready_for_shipment: "Ready to go!" 
       }
     end

Console:

       request.sum = 3
       request.payed!
       request.status      # >> payed
       request.t_status    # >> "Payed 3 dollars"
       Request.t_statuses  # >> { in_cart: -> { I18n.t("request.status.in_cart") }, ....  }

If you need some substitution you can go like this:

       localize_enum :status, {
             ..
        delivered: "Delivered at: %{date}"
       }
       request.delivered!
       request.t_status % {date: Time.now.to_s}  >> Delivered at: 05.02.2016

If you need select status on form:
    
        f.select :status, Request.t_statuses.invert.to_a


### Enum Sets (ext_enum_sets)
 
 **Use-case** For example you have pay bills of different types, and you want to group some types in debit and credit "super-types", and have scope PayBill.debit, instance method with question mark as usual enum does pay_bill.debit?.
 
 You can do this with method **ext_enum_sets**, it creates: scopes for subsets like enum did, instance method with ? similar to enum methods, and so...
 
 I strongly recommend you to create special comment near method call, to remember what methods will be defined on instance, on class itself, and what scopes will be defined
  
      class Request
            ...
           #instance methods: non_payed?, delivery_set?, in_warehouse?
           #scopes: non_payed, delivery_set, in_warehouse
           #scopes: with_statuses, without_statuses
           #class methods: non_payed_statuses, delivery_set_statuses ( = [:in_cart, :waiting_for_payment], [:ready_for_shipment, :on_delivery, :delivered].. )
           
           ext_enum_sets :status, {
                           non_payed: [:in_cart, :waiting_for_payment],
                           delivery_set: [:ready_for_shipment, :on_delivery, :delivered]  #for shipping department for example
                           in_warehouse: [:ready_for_shipment]                            #it's just for example below
                         }
      end

Console:

        request.waiting_for_payment!
        request.non_payed?                     # >> true
        
        Request.non_payed.exists?(request)     # >> true
        Request.delivery_set.exists?(request)  # >> false
        
        Request.non_payed_statuses             # >> [:in_cart, :waiting_for_payment]
        
        Request.with_statuses( :payed, :in_cart )       # >> scope for all in_cart and payed requests
        Request.without_statuses( :payed )              # >> scope for all requests with statuses not eq to payed
        Request.without_statuses( :payed, :non_payed )  # >> scope all requests with statuses not eq to payed and in_cart + waiting_for_payment


#### Rem:

You can call ext_enum_sets more than one time defining a superposition of already defined sets:

      class Request
        ...
        ext_enum_sets (... first time you call ext_enum_sets )
        ext_enum_sets :status, {
                          already_payed: ( [:payed] | delivery_set_statuses ),
                          outside_wharehouse: ( delivery_set_statuses - in_warehouse_statuses )... # any other array operations like &, + and so can be used
                       }

### Mass-assign ( mass_assign_enum )
 
 Syntax sugar for mass-assigning enum values. 
 
 **Use-case:** it's often case when I need bulk update without callbacks, so it's gets frustrating to repeat: some_scope.update_all(status: Request.statuses[:new_status], update_at: Time.now)
 If you need callbacks you can do like this: some_scope.each(&:new_stat!) but if you don't need callbacks and you has hundreds and thousands of records to change at once you need update_all

     class Request
       ...
       mass_assign_enum( :status )
     end

 Console:
 
        request1.in_cart!
        request2.waiting_for_payment!
        Request.non_payed.payed!
        request1.payed?                         # >> true
        request2.payed?                         # >> true
        request1.updated_at                     # >> ~ Time.now
        defined?(Request::MassAssignEnum) # >> true
        
        
        order.requests.already_payed.count          # >> N
        order.requests.delivered.count              # >> M
        order.requests.already_payed.delivered!
        order.requests.already_payed.count          # >> 0
        order.requests.delivered.count              # >> N + M


####Rem:

 **mass_assign_enum** accepts additional options as last argument. Calling  
 
    mass_assign_enum( :status ) 
 
 actually is equal to call:
  
    mass_assign_enum( :status, { relation: true, association_relation: true } )

###### Meaning:

 relation: true - Request.some_scope.payed! - works

 association_relation: true - Order.first.requests.scope.new_stat! - works
 
 **but it wouldn't work without 'scope' part!** If you want to use it without 'scope' you may do it this way:
 
     class Request
       ...
       mass_assign_enum( :status, relation: true, association_relation: false )
     end

     class Order
      has_many :requests, extend: Request::MassAssignEnum
     end
    
     Order.first.requests.respond_to?(:in_cart!)  # >> true

#### Rem2:
 You can mass-assign more than one enum ::MassAssignEnum module will contain mass assign for both. It will break nothing since all enum name must be uniq across model

## Tests
 Right now goes without automated tests :(
 
## Development


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/alekseyl/enum_ext or by email: leshchuk@gmail.com


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

