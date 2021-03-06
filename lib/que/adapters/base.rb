module Que
  module Adapters
    autoload :ActiveRecord,   'que/adapters/active_record'
    autoload :ConnectionPool, 'que/adapters/connection_pool'
    autoload :PG,             'que/adapters/pg'
    autoload :Sequel,         'que/adapters/sequel'

    class Base
      def initialize(thing = nil)
        @statement_mutex = Mutex.new
      end

      # The only method that adapters really need to implement. Should lock a
      # PG::Connection (or something that acts like a PG::Connection) so that
      # no other threads are using it and yield it to the block.
      def checkout(&block)
        raise NotImplementedError
      end

      def execute(*args)
        checkout { |conn| conn.async_exec(*args) }
      end

      def execute_prepared(name, params = [])
        checkout do |conn|
          unless statements_prepared(conn)[name]
            conn.prepare("que_#{name}", SQL[name])
            statements_prepared(conn)[name] = true
          end

          conn.exec_prepared("que_#{name}", params)
        end
      end

      private

      # Each adapter needs to remember which of its connections have prepared
      # which statements. This is a shared data structure, so protect it. We
      # assume that the hash of statements for a particular connection is only
      # being accessed by the thread that's checked it out, though.
      def statements_prepared(conn)
        @statement_mutex.synchronize do
          @statements_prepared       ||= {}
          @statements_prepared[conn] ||= {}
        end
      end
    end
  end
end
