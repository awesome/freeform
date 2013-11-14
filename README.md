# FreeForm

FreeForm is a gem designed to give you total control over form objects, allowing you to map form objects to domain objects in any way that you see fit.

It is still a very-pre-beta work in progess, but hopefully it can showcase the power of form objects.

FreeForm is designed primarily with Rails in mind, but it should work on any Ruby framework.

FreeForm is compatible with (as far as I know) most form gems, including simpleform, formbuilder, and Ryan Bate's nested_form gem.

## Installation

Add this line to your application's Gemfile:

    gem 'freeform'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install freeform

## How It Works

FreeForm can 1-*n* models, exposing whatever attributes you wish from each model, and delegating those assignments back to the models themselves.  This means that one form can be used just as easily to support parent/child models, multiple unrelated models, etc.  Your database relationships can change, and your forms won't have to.

**Example**

```ruby
class RegistrationForm < FreeForm::Form
  form_models :user, :address

  property :username,              :on => :user
  property :email,                 :on => :user
  property :password,              :on => :user

  property :street,                :on => :address
  property :city,                  :on => :address
  property :state,                 :on => :address
  property :zip_code,              :on => :address
end

class User < ActiveRecord::Base
  has_one :address
  ...
end

class Address < ActiveRecord::Base
  belongs_to :user
  ...
end

user = User.new
RegistrationForm.new(:user => user, :address => user.build_address)
```
**Oh No!**
Our domain model has changed, and we needs users to have multiple addresses!  We'll change our model...but our form remains the same.

```ruby
class User < ActiveRecord::Base
  has_many :addresses
  ...
end

class Address < ActiveRecord::Base
  belongs_to :user
  ...
end

user = User.new
RegistrationForm.new(:user => user, :address => user.addresses.build)
```

## Defining Forms

FreeForm doesn't assume a lot, so you need to tell it:
  * The names of the models it's going to be mapping (specified as `form_model` or `form_models`)
  * The properties of the form, and which model they map to (specified as `property` or `properties`).  Properties that don't map to a model are considered to be just form attributes.
  * How to validate, if at all (see below)
  
```ruby
class RegistrationForm < FreeForm::Form
  form_models :user, :address

  property :username,              :on => :user
  property :email,                 :on => :user
  property :password,              :on => :user

  property :street,                :on => :address
  property :city,                  :on => :address
  property :state,                 :on => :address
  property :zip_code,              :on => :address
end

class User < ActiveRecord::Base
  has_one :address
  ...
end

class Address < ActiveRecord::Base
  belongs_to :user
  ...
end

user = User.new
RegistrationForm.new(:user => user, :address => user.build_address)
```
## Form Validations

FreeForm handles validations wherever you define them.  If you want to check model validations, simply specify that option in your form definition

```ruby
class UserForm < FreeForm::Form
  form_models :user
  validate_models  # This will check to see that the :user model itself is valid

  property :username,              :on => :user
  property :email,                 :on => :user
  property :current_password
  
  # But you can also validate in the form itself!
  validates :email, :presence => true  
  validate :valid_current_password
  
  def valid_current_password
    user.password == current_password
  end
end
```
Personally, I use validations in both places to stay DRY.  My domain models have their own validations, which I use for things that are universally true of that model (e.g. email is correctly formatted).  Some forms have validations though that are specific to that form, and they live in the form itself (see above example with `current_password`) 

## Nesting Forms

Sometimes, you need to be able to support a collection of unknown size (e.g. a user with many phone numbers).  Since FreeForm makes no assumptions about your domain models, we nest forms themselves.

```ruby
class UserForm < FreeForm::Form
  form_models :user

  property :username,              :on => :user
  property :email,                 :on => :user
  
  nested_form :phone_numbers do
    form_models :phone
	
	property :area_code,              :on => :phone
	property :number,                 :on => :phone
  end
end
```
**Note:**  The method `nested_form` is also aliased as `has_many` and `has_one`, if you prefer the expressiveness of that syntax.  The functionality is the same in any case.

When using a nested form, the form starts with **no** nested forms pre-built.  FreeForm provides a method called `build_#{nested_form_model}` (e.g. `build_phone_numbers`) that you can use to build a nested form.  You must provide the initializer:
```ruby
form = UserForm.new(:user => User.new)
form.build_phone_numbers(:phone => Phone.new)
form.build_phone_number(:phone => Phone.new) # The singularized version is aliased as well.
```

You can specify the default initializers for that form with the accessor `#{nested_form_name}_form_initializer`.
```ruby
form = UserForm.new(
  :user => User.new, 
  :phone_numbers_form_initializer => {:phone => Phone.new} )

form.build_phone_numbers
form.build_phone_number
```
This is a necessary parameter if you're using the `nested_form` gem, as new nested forms are initialized automatically.

## Initialize With Care!

FreeForm's flexibility comes at a bit of a cost - it makes no assumptions about relationships between initialized models or nested forms.  So initializing the form correctly is important.

** For Example **

```ruby
current_user               # => #<User:0x100124b88>
current_user.phone_numbers # => [#<Phone:0x100194867>, #<Phone:0x100100cd4>]

class UserForm < FreeForm::Form
  form_models :user

  property :username,              :on => :user
  property :email,                 :on => :user
  
  nested_form :phone_numbers do
    form_models :phone
	
	property :area_code,              :on => :phone
	property :number,                 :on => :phone
  end
end

form = UserForm.new(:user => current_user)
```

Think the user's phone numbers will show up as nested forms? **Nope**.  If you want them there, put them there.

```ruby
current_user.phone_numbers.each do |phone_number|
  form.build_phone_number(:phone => phone_number)
end
```

## Extras!

I'm open to trying to build out little helper features wherever possible. Right now, FreeForm comes with one handy option called `form_input_key`.  Setting this determines the parameter key that your forms are rendered with in Rails.

*Why use this?*
Well, I like to keep my form keys fairly concise, but in a bigger application I often end up namespacing my forms.  And changing namespaces sometimes breaks Cucumber specs, which might be hardcoded to find a particular ID.  No more!

```ruby
class MyScope::UserForm < FreeForm::Form
  form_input_key :user # Sets the parameter key for HTML rendering.
  form_models :user

  property :email,                 :on => :user
end
```
Would render with HTML input fields like 
`<input id="user_email" ... name="user[email]"></input>` instead of
`<input id="my_scope_user_form_email" ... name="my_scope_user_form[email]"></input>`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
