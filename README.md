A fluffy corded and threaded pool. The smallest thread pool available on the market to date.
The Puli is enumerable, mappable, parallel and also _tiny._

To execute lots of things in parallel:

```ruby
puli = Puli.new(num_threads: 4, tasks: uris)
response_bodies = puli.map do |uri_task|
  Patron::Session.new.get(uri_task).body
end
```
 
You can spool tasks one by one as well
 
```ruby
puli = Puli.new(num_threads: 4)
database.each_row do |row|
  puli << row
end

puli.each do |database_row|
  output.write(database_row)
end
```
 
 If an exception is raised during the execution of a task, Puli will make sure other threads stop before starting
 their next iteration:

```ruby
puli = Puli.new(num_threads: 4, tasks: five_thousand_heavy_items)
puli.each do |item|
  #..... raise TimeoutError
end
# Will not have executed all the five thousand heavy items, just some,
# and will also raise TimeoutError up into the caller, regardless of whether
# Thread.abort_on_exception is set to true.
```

# Execution order (`map` vs. `each`)

Since `Puli#each` is presumed to generate side effects and should not slow down execution it yields immediately, so
the order of execution is undefined:

```ruby
puli = Puli.new(num_threads: 4, tasks: 1..10.to_a)
puli.each do |item| # Will yield numbers from 1 to 10 but in arbitrary order
  fetch_item(item)
end
```

However `Puli#map` can "hold" its return value until the ordering can be re-established, and will always return
the tasks in order they were submitted or in the order the tasks were given in the `tasks:` keyword argument:


```ruby
puli = Puli.new(num_threads: 4, tasks: 1..10.to_a)
fetched_items = puli.map do |i|
   # Will run the block in arbitrary order among tasks, due to out-of-order execution
  fetch_item(i)
end
fetched_items #=> [<Item 1>, <Item 2>, ...]_
```

## Contributing to puli
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2016 Julik Tarkhanov. See LICENSE.txt for
further details.

