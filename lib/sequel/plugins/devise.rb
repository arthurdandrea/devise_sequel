require 'devise_sequel'

module Sequel
  module Plugins
    module Devise
      # Callback types used by Devise
      # Adding types here would be necessary but not sufficient if Devise
      # used more callbacks in the future.
      # (see method_added and InstanceMethod included hooks below)
      DEVISE_CALLBACK_METHODS = [:create, :update, :validation]

      def self.apply (model, *args)
        model.plugin :active_model
        model.plugin :active_model_callbacks
        model.extend ::Devise::Models
      end

      def self.configure (model, *args)
        model.devise(*args) unless args.empty?
      end

      module ClassMethods

        # for some reason devise tests still use create! from the model itself
        def create! (*args)
          # to_adapter.create!(*args)
          o = new(*args)
          o.save(:raise_on_failure => true)
          o
        end

      end # ClassMethods
      
      module InstanceMethods

        def changed?
          modified?
        end

        def save!
          save(:raise_on_failure => true)
        end

        def update_attribute(k, v)
          set(k => v)
          save(:changes => true, :validate => false)
        end

        def update_attributes (*args)
          update(*args)
        end

        def attributes= (hash, guarded=true)
          (guarded) ? set(hash) : set_all(hash)
        end

      end # InstanceMethods

    end # Devise
  end
end
