require 'nested_form/view_helper'

module FreeForm
  module ViewHelper
    include NestedForm::ViewHelper

    def nested_form_for(*args, &block)
      options = args.extract_options!.reverse_merge(:builder => FreeForm::Builder)
      form_for(*(args << options)) do |f|
        capture(f, &block).to_s << after_nested_form_callbacks
      end
    end

    if defined?(FreeForm::SimpleBuilder)
      def simple_nested_form_for(*args, &block)
        options = args.extract_options!.reverse_merge(:builder => FreeForm::SimpleBuilder)
        simple_form_for(*(args << options)) do |f|
          capture(f, &block).to_s << after_nested_form_callbacks
        end
      end
    end

    if defined?(FreeForm::FormtasticBuilder)
      def semantic_nested_form_for(*args, &block)
        options = args.extract_options!.reverse_merge(:builder => FreeForm::FormtasticBuilder)
        semantic_form_for(*(args << options)) do |f|
          capture(f, &block).to_s << after_nested_form_callbacks
        end
      end
    end

    if defined?(FreeForm::FormtasticBootstrapBuilder)
      def semantic_bootstrap_nested_form_for(*args, &block)
        options = args.extract_options!.reverse_merge(:builder => FreeForm::FormtasticBootstrapBuilder)
        semantic_form_for(*(args << options)) do |f|
          capture(f, &block).to_s << after_nested_form_callbacks
        end
      end
    end

    def after_nested_form(association, &block)
      @associations ||= []
      @after_nested_form_callbacks ||= []
      unless @associations.include?(association)
        @associations << association
        @after_nested_form_callbacks << block
      end
    end

    private
      def after_nested_form_callbacks
        @after_nested_form_callbacks ||= []
        fields = []
        while callback = @after_nested_form_callbacks.shift
          fields << callback.call
        end
        fields.join(" ").html_safe
      end
  end
end