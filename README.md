# video_rental_store
A refactoring exercise of a video rental store.

## Gem dependencies

rspec ~> 3.10.0
nokogiri ~> 1.12.5
money ~> 6.16.0

## To Run (in bash)
$ ./run.sh

## Brief

### Requirements
Add a function to print out the statement in HTML. Consider that in the future you may be asked to add additional formats.

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
