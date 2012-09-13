require 'devise_sequel'

module Sequel
  module Plugins
    module ActiveModelCallbacks
      # Callback types used by Devise
      # Adding types here would be necessary but not sufficient if Devise
      # used more callbacks in the future.
      # (see method_added and InstanceMethod included hooks below)
      DEVISE_CALLBACK_METHODS = [:create, :update, :validation]

      def self.apply (model, *args)
        model.plugin :active_model
        model.extend ::ActiveModel::Callbacks
        model.define_model_callbacks(*DEVISE_CALLBACK_METHODS, :scope => :name)
      end

      module ClassMethods

        # Redefine any model defined methods requiring a callback wrapper
        # then re-include the module containing the method as defined below.
        # This allows save, update or validate to be overwridden in the model class
        # and still have the callbacks run before/after them.
        def method_added(sym)
          case sym
          when :save
            define_method(:model_defined_save, instance_method(sym))
            self.include SaveInstanceMethod
          when :update
            define_method(:model_defined_update, instance_method(sym))
            self.include UpdateInstanceMethod
          when :validate
            define_method(:model_defined_validate, instance_method(sym))
            self.include ValidateInstanceMethod
          end
        end

      end # ClassMethods
      
      module InstanceMethods

        # Include the callback wrappers. This assumes that plugin :devise is called
        # before any redefinition of their methods in the model.
        def self.included(mod)
          mod.include SaveInstanceMethod
          mod.include UpdateInstanceMethod
          mod.include ValidateInstanceMethod
        end

      end # InstanceMethods

      # modules containing the wrappers to be re-included if the
      # method is defined in the model
      module SaveInstanceMethod
        # redefine Sequel methods which require callback handling
        # calling super or the redefined method so they still work
        def save(*args)
          if new?
            run_callbacks(:create) do
              if self.class.method_defined?(:model_defined_save)
                model_defined_save(*args)
              else
                super(*args)
              end
            end
          else
            run_callbacks(:update) do
              if self.class.method_defined?(:model_defined_save)
                model_defined_save(*args)
              else
                super(*args)
              end
            end
          end
        end
      end # SaveInstanceMethod

      module UpdateInstanceMethod
        def update(*args)
          run_callbacks(:update) do
            if self.class.method_defined?(:model_defined_update)
              model_defined_update(*args)
            else
              super(*args)
            end
          end
        end
      end # UpdateInstanceMethod

      module ValidateInstanceMethod
        def validate(*args)
          run_callbacks(:validation) do
            if self.class.method_defined?(:model_defined_update)
              model_defined_update(*args)
            else
              super(*args)
            end
          end
        end
      end # ValidateInstanceMethod

    end # Devise
  end
end
