# video_rental_store
A refactoring exercise of a video rental store.

## Gem dependencies

rspec ~> 3.10.0

nokogiri ~> 1.12.5

money ~> 6.16.0

## To run
$ ./run.sh

## Brief

### Requirements
Read the code and implement the remaining requirements. In addition, include a function to print out the statement in HTML. Consider that in the future you may be asked to add additional formats. Feel free to refactor but stay within the scope of the business logic. 

### Business Logic
A customer can printout his statement. On the statement must appear:
- The customer's name
- Each movie he rents, with its price
- The total amount owed
- The frequent renter points he's earned

For each movie category, some rules apply.

Regular movies:
- amount is $2.00 for the first 2 days
- an extra $1.50 is added for each additional day
- you get 1 frequent renter point

New releases:
- amount is $3.00 per day rented
- you get 1 frequent renter point for the first day
- you get 1 extra frequent renter point if you rent more than a day

Children's movies:
- amount is $1.50 for the first 3 days
- an extra $1.50 is added for each additional day
- you get 1 frequent renter point

### Original Code
```
class Customer

  attr_reader :name

  def initialize(name)
    @name = name
    @rentals = []
  end
  
  def add_rental(movie, rented_days)
    @rentals << Rental.new(movie, rented_days)
  end

  def statement
    puts "Rental Store Statement"
    puts "============================================="
    puts "Customer: #{@name}"
    @rentals.each do |rental|
      if rental.movie.category == Movie::REGULAR
        rental_price  = 2
        if rental.rented_days > 2
          rental_price = rental_price + (1.5 * (rental.rented_days - 2))
        end
        puts "\t#{rental.movie.title}; Price: #{rental_price}"
      elsif rental.movie.category == Movie::NEW_RELEASE
        rental_price = 3
        puts "\t#{rental.movie.title}; Price: #{rental_price}"
      elsif rental.movie.category == Movie::CHILDRENS
        rental_price  = 1.5
        if rental.rented_days > 3
          rental_price = rental_price + (1.5 * (rental.rented_days - 3))
        end
        puts "\t#{rental.movie.title}; Price: #{rental_price}"
      end 
    end
  end
end
class Rental
  attr_reader :rented_days, :movie

  def initialize(movie, rented_days)
    @movie       = movie
    @rented_days = rented_days
  end
end

class Movie
  REGULAR = 1
  NEW_RELEASE = 2
  CHILDRENS = 3

  attr_reader :title, :category
  
  def initialize(title, category)
    @title    = title
    @category = category
  end
end

# SEED some data to print out a statement
customer = Customer.new("Bob")
customer.add_rental(Movie.new("Mad Max", 1), 4)  # rented Regular movie (2 day extra charge)
customer.add_rental(Movie.new("Dune", 2), 10) # rented new Release movie (no extra charge)
customer.add_rental(Movie.new("Babe", 3), 4)   # rented a childrens movie (1 day extra charge)

customer.statement
```
