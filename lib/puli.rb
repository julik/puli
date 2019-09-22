require 'thread'

class Puli
  VERSION = '1.0.2'

  Task = Struct.new(:payload, :index)

  include Enumerable

  def initialize(num_threads: 3, tasks: [])
    @num_threads = num_threads.to_i
    @q = Queue.new
    @index = 0
    tasks.map{|t| self << t }
  end

  def <<(task_payload)
    @index += 1
    @q << Task.new(task_payload, @index)
  end

  def map
    in_execution_order = []
    mux = Mutex.new
    each do |*payload, index:|
      result = yield(*payload)
      mux.synchronize { in_execution_order << Task.new(yield(*payload), index) }
    end
    in_execution_order.sort_by(&:index).map(&:payload)
  end

  def each
    last_captured_error = false
    in_execution_order = {}
    threads = (1..@num_threads.to_i).map do
      Thread.new do
        loop do
          break if last_captured_error
          begin
            task = @q.pop(non_block=true)
            yield(task.payload, index: task.index)
          rescue ThreadError
            break # Queue emptied
          rescue Exception => e
            last_captured_error = e
          end
        end
      end
    end
    threads.map(&:join)
    raise last_captured_error if last_captured_error
    self
  end
end
