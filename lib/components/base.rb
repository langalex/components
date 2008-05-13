module Components
  class Base
    include ::ActionController::UrlWriter

    # for request forgery protection compatibility
    attr_accessor :form_authenticity_token #:nodoc:
    delegate :request_forgery_protection_token, :allow_forgery_protection, :to => "ActionController::Base"
    def protect_against_forgery? #:nodoc:
      allow_forgery_protection && request_forgery_protection_token
    end

    class << self
      # The view paths to search for templates. Typically this will only be "app/components", but
      # if you have a plugin that uses Components, it may add its own directory (e.g.
      # "vendor/plugins/scaffolding/components/" to this array.
      def view_paths
        if read_inheritable_attribute(:view_paths).nil?
          write_inheritable_attribute(:view_paths, [File.join(RAILS_ROOT, 'app', 'components')])
        end
        read_inheritable_attribute(:view_paths)
      end

      def name #:nodoc:
        @name ||= self.to_s.underscore.sub("_component", "")
      end
    end

    # must be public for access from ActionView
    def logger #:nodoc:
      RAILS_DEFAULT_LOGGER
    end

    protected

    # When the string your component must return is complex enough to warrant a template file,
    # this will render that file and return the result. Any template engine (erb, haml, etc.)
    # that ActionView is capable of using can be used for templating.
    #
    # All instance variables that you create in the component action will be available from
    # the view. There is currently no other way to provide variables to the views.
    #
    # === Inferred Template Name
    #
    # If you call render without a file name, it will:
    #  * assume that the name of the calling method is also the name of the template file
    #  * search for the named template file in the directory of this component's views, then the directories of all parent components
    #
    # This means that if you have:
    #
    #   class UsersComponent < Components::Base
    #     def details(user_id)
    #       render
    #     end
    #   end
    #
    # Then render will essentially assume that you meant to render "users/details", which may
    # be found at "app/components/users/details.erb".
    def render(file = nil)
      # infer the render file basename from the caller method.
      unless file
        caller.first =~ /`([^']*)'/
        file = $1
      end

      # pick the closest parent component with the file
      component = self.class
      unless file.include?("/")
        until template.file_exists? "#{component.name}/#{file}" or component.superclass == Components::Base
          component = component.superclass
        end
      end

      template.render("#{component.name}/#{file}")
    end

    # creates and returns a view object for rendering the current action.
    # note that this freezes knowledge of view_paths and assigns.
    def template #:nodoc:
      @template ||= Components::View.new(self.class.view_paths, assigns_for_view, self)
    end

    # should return a hash of all instance variables to assign to the view
    def assigns_for_view #:nodoc:
      @assigns_for_view ||= (instance_variables - unassignable_instance_variables).inject({}) do |hash, var|
        hash[var[1..-1]] = instance_variable_get(var)
        hash
      end
    end

    # should name all of the instance variables used by Components::Base that should _not_ be accessible from the view.
    def unassignable_instance_variables #:nodoc:
      %w(@component_name @template)
    end
  end
end