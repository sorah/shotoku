module Shotoku
  class Config
    def initialize(*scopes)
      @configurable_klass = Class.new(Configurable::Base)
      scopes = scopes.map { |_|
        Configurable.const_get(_) rescue Configurable.const_get(_.to_s.capitalize) }
      scopes.each do |mod|
        @configurable_klass.send(:include, mod)
      end
      @configurable = @configurable_klass.new
    end

    def options
      @configurable.options
    end

    def configure(&block)
      @configurable.configure(&block)
    end

    def load(*files)
      @configurable.load(*files)
    end

    def validate
      @configurable.validate
    end

    module Configurable
      module ClassMethods
        def option(name, kind: nil, block: false, multiple: false, required: false, accept_options: false)
          kind = Proc if block
          self.send(:define_method, name) { |value = nil, options = {}, &blok|
            @options[name] ||= [] if multiple

            if block
              if accept_options && value.kind_of?(Hash) && blok
                options, value = value, nil
              end

              value = blok || value
              kind ||= Proc
            end

            if value
              if kind && !value.kind_of?(kind)
                raise ArgumentError, "#{name} should be a kind_of #{kind}"
              end
              if accept_options && !options.kind_of?(Hash)
                raise ArgumentError, "option should be a kind_of Hash"
              end

              value_key = accept_options.is_a?(Symbol) ? accept_options : :value
              value = options.merge(value_key => value) if accept_options

              if multiple
                @options[name].push value
              else
                @options[name] = value
              end
            end

            @options[name]
          }
          self.required_options << name if required
          self.multiple_options << name if multiple
          name
        end

        def required_options
          @required_options ||= []
        end

        def multiple_options
          @multiple_options ||= []
        end

        def included(klass)
          klass.multiple_options.push(*multiple_options).uniq!
          klass.required_options.push(*required_options).uniq!
        end

      end

      class Base
        extend ClassMethods
        class ValidationError < Exception; end


        def initialize
          @options = {}
        end

        attr_reader :options

        def load(*files)
          files.each do |script|
            run(File.read(script))
          end

          validate
        end

        def run(script)
          configure { eval(script) }
        end

        def configure(&block)
          multiple_options.each { |key| @options[key] = [] }
          self.instance_eval(&block)
        end

        def validate
          missing_keys = required_options.reject do |key|
            @options.key?(key) && (multiple_options.include?(key) ? (!@options[key].empty?) : true)
          end
          unless missing_keys.empty?
            raise ValidationError, "These options are required but missing: #{missing_keys.inspect}"
          end
        end

        private

        def required_options
          self.class.required_options
        end

        def multiple_options
          self.class.multiple_options
        end
      end

      module Source
        extend ClassMethods

        option :source, multiple: true, required: true, accept_options: true
        # classifier
      end

      module Recipe
        extend ClassMethods

        option :build_using, accept_options: true
        option :build_script, kind: String

        option :upload_builds, accept_options: true
      end

      module Operation
        extend ClassMethods

        option :operator, required: true, accept_options: true, block: true, kind: Object
        option :source_condition, block: true, multiple: true
        option :build_flags, required: true, multiple: true
        option :runtime_flags, required: true, multiple: true
      end

      module Script
        extend ClassMethods

        option :script, required: true, kind: String
      end

      module Worker
        extend ClassMethods

        option :node, kind: Hash, multiple: true
      end

      module Test
        extend ClassMethods

        option :simple
        option :test_kind, kind: Integer
        option :test_block, block: true
        option :test_block_options, block: true, accept_options: :proc
        option :test_multiple, multiple: true
        option :test_options, accept_options: :value
      end

      module Test2
        extend ClassMethods

        option :test_required, required: true
      end

      module Test3
        extend ClassMethods

        option :test_multiple_required, multiple: true, required: true
      end
    end
  end
end
