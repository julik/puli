require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'Puli' do
  it 'executes all the queued tasks' do
    out = StringIO.new
    mux = Mutex.new
    p = Puli.new(num_threads: 25)
    500.times {|i|
      p << "This is task #{i}"
    }
    p.each do | task_string |
      sleep(rand * 0.8)
      mux.synchronize { out.puts(task_string) }
    end
    
    results = out.string
    sorted_results = results.split("\n").reject(&:empty?).sort
    expect(sorted_results.length).to eq(500)
  end
  
  it 'raises the exception and stops executing the tasks on the first exception' do
    20.times do 
      p = Puli.new(num_threads: 4)
      1000.times {|i| p << i }
      processed = []
      expect {
        p.each do |t|
          raise "This is wrong" if rand > 0.8
          processed << t
        end
      }.to raise_error(/This is wrong/)
      expect(processed.length).to be < 300
    end
  end

  it 'allows mapping over the result' do
    p = Puli.new(num_threads: 4)
    20.times {|i| p << i }
    results = p.map{|task| task ** 2 }
    sorted = results.sort
    expect(sorted.length).to eq(20)
    expect(sorted[-1]).to eq(19 ** 2)
  end

  it 'maps over the result in order, even when iteration is executed out of order' do
    order_as_submitted = (1..64).to_a
    p = Puli.new(num_threads: 4, tasks: order_as_submitted)
    order_of_execution = p.map do |number|
      sleep(rand / 14)
      number
    end
    expect(order_of_execution).to eq(order_as_submitted)
  end

  it 'allows mapping over the result' do
    p = Puli.new(num_threads: 4)
    20.times {|i| p << i }
    results = p.map{|task| task ** 2 }
    sorted = results.sort
    expect(sorted.length).to eq(20)
    expect(sorted[-1]).to eq(19 ** 2)
  end
  
  it 'supports the tasks[] kwarg' do
    p = Puli.new(num_threads: 4, tasks: (1..100))
    results = p.map{|task| task + 1 }
    sorted = results.sort
    expect(sorted.length).to eq(100)
    expect(sorted[0]).to eq(1 + 1)
    expect(sorted[-1]).to eq(100 + 1)
  end
end
