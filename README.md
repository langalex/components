## Components

This plugin attempts to implement components in the simplest, cleanest, fastest way possible. Inspired by the Cells plugin (http://cells.rubyforge.org) by Nick Sutterer and Peter Bex.

A component can be thought of as a very lightweight controller with supporting view templates. The difference between a component "controller" and a Rails controller is that the component controller's methods are very much normal methods - they accept arguments, and they return a string. There is no magical auto-rendering, and there is no access to data that is not a) in the arguments or b) in the database. For example, there is no access to the request, the request parameters, or the session. This is designed to encourage good design and reuse of components, and to ensure that they don't take over the request/response job of your Rails controllers.

Speaking imprecisely, components prepare for and then render templates.

## Usage

Note that these examples are very simplistic and would be better implemented using Rails partials.

### Generator

Running `script/generator users details` will create a UsersComponent with a "details" view. You might then flesh out the templates like this:

    class UsersComponent < Components::Base
      def details(user_or_id)
        @user = user_or_id.is_a?(User) ? user_or_id : User.find(user_or_id)
        render
      end
    end

### From ActionController

    class UsersController < ApplicationController
      def show
        return :text => component("users/detail", params[:id])
      end
    end

### From ActionView

    <%= component "users/detail", @user %>

## More Features

### Caching

Any component action may be cached using the fragment caching you've configured on ActionController::Base. The command to cache a component action must come after the definition of the action itself. This is because the caching method wraps the action, which makes the caching work even if you call the action directly.

Example:

    class UsersComponent < Components::Base
      def details(user_id)
        @user = User.find(user_id)
        render
      end
      cache :details, :expires_in => 15.minutes
    end

This will cache the returns from UsersComponent#details using a cache key like "users/details/5", where 5 is the user_id. The cache will only be good for fifteen minutes. See Components::Caching for more information.

### Helpers

All of the standard helper functionality exists for components. You may define a method on your component controller and use :helper_method to make it available in your views, or you may use :helper to add entire modules of extra methods to your views.

Be careful importing existing helpers, though, as some of them may try and break encapsulation by reading from the session, the request, or the params. You may need to rewrite these helpers so they accept the necessary information as arguments.

### Inherited Views

Assume two components:

    class ParentComponent < Components::Base
      def one
        render
      end

      def two
        render
      end
    end

    class ChildComponent < ParentComponent
      def one
        render
      end

      def three
        render "one"
      end
    end

Both methods on the ChildComponent class would first try and render "/app/components/child/one.erb", and if that file did not exist, would render "/app/components/parent/one.erb".

### Standard Argument Options

You may find yourself constantly needing to pass a standard set of options to each component. If so, you can define a method on your controller that returns a hash of standard options that will be merged with the component arguments and passed to every component.

Suppose a given component:

    class GroupsComponent < Components::Base
      def details(group_id, options = {})
        @user = options[:user]
        @group = Group.find(group_id)
        render
      end
    end

Then the following setup:

    class GroupsController < ApplicationController
      def show
        render :text => component("groups/details", params[:id])
      end

      protected

      def standard_component_options
        {:user => current_user}
      end
    end

Would expand to:

    component("groups/details", params[:id], :user => current_user)

## Components Philosophy

I wrote this components plugin after evaluating a couple of existing ones, reflecting a bit, and either stealing or composing the following principles. I welcome all debate on the subject.

### Components <em>should not</em> simply embed existing controller actions.

Re-using existing controller actions introduces intractable performance problems related to redundant controller filters and duplicate request-cached variables.

### Components <em>should not</em> have the concept of a "request" or "current user".

Everything should be provided as an argument to the component - it should not have direct access to the session, the params, or any other aspect of the request. This means that components will never intelligently respond_to :html, :js, :xml, etc.

### Components _should_ complement RESTful controller design.

The path of least resistance in Rails includes RESTful controller design to reduce code redundancy. Components should only be designed for use cases where RESTful controller design is either awkward or impossible. This compatibility will reduce the maintenance effort for components and help them grow with Rails itself.

## Troubleshooting

Q: I want to render partials from my app/views directory in a component view but it doesn't work  
A: You have to add the view path of your normal views to the view paths of the components. One solution would be to overwrite the `view_paths` method in your component:

    def self.view_paths
      super + [Rails.root + 'app/views']
    end

Q: I want to use a method from one of my helpers in app/helpers but I get a method missing error  
A: Call `helper :all` in your component, just like you would in a controller

## Copyright

Copyright (c) 2008 Lance Ivy, released under the MIT license
