require 'thread'

class Puli
  VERSION = '1.0.1'

  include Enumerable

  def initialize(num_threads: 3, tasks: [])
    @num_threads = num_threads.to_i
    @q = Queue.new
    tasks.map{|t| @q << t }
  end

  def <<(task)
    @q << task
  end

  def each
    last_captured_error = false
    threads = (1..@num_threads.to_i).map do
      Thread.new do
        loop do
          break if last_captured_error
          begin
            task = @q.pop(non_block=true)
            yield(task)
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
