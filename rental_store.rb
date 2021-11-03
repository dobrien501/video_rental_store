require "rspec/autorun"
require "date"
require "nokogiri"

# instance of Customer can rent movies and accumulate rental points
# and print a statement of rental history
class Customer

  attr_reader :name, :rentals

  def initialize(name: , options: {})
    @name                = name
    @rentals             = []
    @options             = {      # setup options with their defaults
      formatter: :html
    }.merge(options)
  end

  def add_rental(movie, rented_at)
    @rentals << Rental.new(movie: movie, rented_at: rented_at)
  end

  def total_rental_points
    rentals.inject(0) { |sum, rental| sum + rental.rental_points }
  end

  def total_amount
    rentals.inject(0) { |sum, rental| sum + rental.total_amount }
  end

  def statement
    formatter = begin 
      Object.const_get("#{@options[:formatter].to_s.capitalize}Formatter").new(self)
    rescue NameError => e
      puts "Unknown formatter #{@options[:formatter]}. Falling back to PlainFormatter"
      PlainFormatter.new(self)
    end
    formatter.statement
  end
end

# represents the transaction of having rented a movie
class Rental
  attr_reader :rented_at, :movie

  def initialize(movie:, rented_at:)
    @movie     = movie
    @rented_at = rented_at 
  end

  def total_amount
    movie.category.amount_for_rental(rented_at)
  end

  def rental_points
    movie.category.rental_points_for_rental(rented_at)
  end
end

class Movie
  attr_reader :title, :category

  def initialize(title:, category:)
    @title    = title
    @category = category
  end

  def price
    category.price_amount
  end
end

# Base class to represent categories
# sets up the standard properties of a category
# and defines the behaviour for calculating the amount owed in a rental period
# subclasses can override with their own behaviours.
class Category
  attr_reader :price_amount, :extra_price, :rental_days, :rental_point

  def initialize
    @price_amount   = self.class::PRICE_AMOUNT
    @extra_price    = self.class::EXTRA_PRICE
    @rental_point   = self.class::RENTAL_POINT
    @rental_days    = self.class::RENTAL_DAYS
  end

  # returns the price of a rental of this category for a given rental date
  # can apply extra charges for late rentals when rental_days and extra_price are set
  def amount_for_rental(rented_at)
    amount         = price_amount 
    additonal_days = [0, days_rented(rented_at) - rental_days].max  # only interested in positive
    amount        += extra_price * additonal_days
    
    amount
  end

  def rental_points_for_rental(rented_at)
    rental_point
  end

  private

  def days_rented(rented_at)
    (Date.today - rented_at).to_i 
  end
end

# BEGIN sub-categories
class RegularCategory < Category
  PRICE_AMOUNT = 2.00
  EXTRA_PRICE  = 1.50
  RENTAL_DAYS  = 2
  RENTAL_POINT = 1
end

class NewReleaseCategory < Category
  PRICE_AMOUNT       = 3.00
  EXTRA_PRICE        = 0
  RENTAL_DAYS        = 0   # 0 = unlimited rental period  (no extra charge penalty)
  RENTAL_POINT       = 1
  EXTRA_RENTAL_POINT = 1
  EXTRA_RENTAL_POINT_QUALIFIER_IN_DAYS = 1
  
  attr_reader :extra_rental_point

  def initialize
    super
    @extra_rental_point = EXTRA_RENTAL_POINT
  end

  def rental_points_for_rental(rented_at)
    points = super(rented_at)
    if days_rented(rented_at) > EXTRA_RENTAL_POINT_QUALIFIER_IN_DAYS
      points += extra_rental_point
    end
    points
  end
end

class ChildrensCategory < Category
  PRICE_AMOUNT       = 1.50
  EXTRA_PRICE        = 1.50
  RENTAL_DAYS        = 3
  RENTAL_POINT       = 1
end

# END subcategories

# base class for establishing interface for printing customer statement
# outputs to stdout
# subclass to support other formats; html, xml, json etc.
class Formatter
  attr_reader :customer
  
  def initialize(customer)
    @customer = customer
  end

  def statement
    raise 'to be implemented by subclassess'
  end
end

class PlainFormatter < Formatter
  def statement
    puts "Rental Store Statement as of #{Date.today}"
    puts "============================================="
    puts "Customer: #{customer.name}, Total: #{customer.total_amount}, Points: #{customer.total_rental_points}"
    customer.rentals.each do |rental|
      puts "\t#{rental.movie.title}; Price: #{rental.movie.price} Owed: #{rental.total_amount} Rented On: #{rental.rented_at.to_s}"
    end
  end
end
class HtmlFormatter < Formatter
  def statement
    builder = ::Nokogiri::HTML::Builder.new do |doc|
      doc.html {
        doc.body {
          doc.h1 {
            doc.text "Rental Store Statement as of #{Date.today}"
          }
          doc.p {
            doc.text "Customer: #{customer.name}, Total: #{customer.total_amount}, Points: #{customer.total_rental_points}"
          }
          doc.table {
            doc.thead {
              doc.tr {
                doc.th {
                  doc.text "Title"
                }
                doc.th {
                  doc.text "Price"
                }
                doc.th {
                  doc.text "Owed"
                }
                doc.th {
                  doc.text "Rented On"
                }
              }
            }
            doc.tbody {
              customer.rentals.each do |rental|
                doc.tr {
                  doc.td {
                    doc.text "#{rental.movie.title}"
                  }
                  doc.td {
                    doc.text "#{rental.movie.price}"
                  }
                  doc.td {
                    doc.text "#{rental.total_amount}"
                  }
                  doc.td {
                    doc.text "#{rental.rented_at.to_s}"
                  }
                }
              end
            }
          }
        }
      }
    end
    puts builder.to_html
  end
end

RSpec.describe "Rental Store" do
  let(:customer) { Customer.new(name: "Bob") }
  let(:movie)    { Movie.new(title: "Memento", category: RegularCategory.new) }

  describe Customer do
    describe "#name" do
      it "has a name" do
        expect(customer.name).to eql "Bob"
      end
      
      context "with rentals" do
        before :each do
          2.times { customer.add_rental movie, Date.today } 
        end
        it "accumulates rental points" do
          expect(customer.total_rental_points).to eql movie.category.rental_point * 2 
        end

        it "returns the total amount owed" do
          expect(customer.total_amount).to eql movie.category.price_amount * 2 
        end
      end
    end

    describe "#statement" do
      before :each do
        allow(STDOUT).to receive(:puts) # silence output
      end

      it "by default uses the html formatter" do
        expect(HtmlFormatter).to receive(:new).and_call_original 
        customer.statement
      end
      
      it "can format in html" do
        customer = Customer.new(name: "Bob", options: {formatter: :html} )
        expect(HtmlFormatter).to receive(:new).and_call_original

        customer.statement
      end
      
      it "can format in plain" do
        customer = Customer.new(name: "Bob", options: {formatter: :plain} )
        expect(PlainFormatter).to receive(:new).and_call_original 

        customer.statement
      end
      
      it "fallbacks to plain formatter when unknown formatter is specified" do
        expect(PlainFormatter).to receive(:new).and_call_original

        customer = Customer.new(name: "Bob", options: {formatter: :xml} )
        customer.statement
      end
    end
  end
  
  describe Rental do
    describe "creating a rental" do
      it "has a timestamp and movie" do
        rented_date = Date.today
        rental      = Rental.new(rented_at: rented_date, movie: movie)
        expect(rental.rented_at).to eql rented_date
        expect(rental.movie.title).to eql movie.title
      end
    end

    describe "#total_amount" do
      it "returns the amount owed depending on category" do
        rental = Rental.new(rented_at: Date.today, movie: movie) 
        expect(rental.total_amount).to eql movie.category.price_amount
      end
    end

    describe "#rental_points" do
      it "returns the points accrued depending on category" do
        rental = Rental.new(rented_at: Date.today, movie: movie) 
        expect(rental.rental_points).to eql movie.category.rental_point
      end
    end
  end
  
  describe RegularCategory do
    it "initializes with a price, extra price, rental days and rental point" do
      category = described_class.new
      expect(category.price_amount).to eql described_class::PRICE_AMOUNT
      expect(category.extra_price).to eql described_class::EXTRA_PRICE
      expect(category.rental_days).to eql described_class::RENTAL_DAYS
      expect(category.rental_point).to eql described_class::RENTAL_POINT
    end
  
    describe "#amount_for_rental" do
      it "charges extra if rental days exceeded" do
        category       = described_class.new
        additonal_days = 2
        rented_at      = Date.today - (described_class::RENTAL_DAYS + additonal_days)
        
        expect(category.amount_for_rental(rented_at)).to eql  described_class::PRICE_AMOUNT + (described_class::EXTRA_PRICE * additonal_days)
      end
  
      it "charges normal price amount if within rental days" do
        category       = described_class.new
        rented_at      = Date.today - (described_class::RENTAL_DAYS - 1)      
        expect(category.amount_for_rental(rented_at)).to eql  described_class::PRICE_AMOUNT
      end
    end
  end

  describe NewReleaseCategory do
    it "adds an extra rental point for longer rents" do
      category = described_class.new
      expect(category.rental_points_for_rental(Date.today)).to eql described_class::RENTAL_POINT

      days_rented = described_class::EXTRA_RENTAL_POINT_QUALIFIER_IN_DAYS+1
      expect(category.rental_points_for_rental(Date.today - days_rented ))
        .to eql (described_class::RENTAL_POINT + described_class::EXTRA_RENTAL_POINT)
    end

    it "has an amount unaffected by no. of days rented" do
      category = described_class.new
      expect(category.amount_for_rental(Date.today - 1000)).to eql described_class::PRICE_AMOUNT
    end
  end

  describe ChildrensCategory do
    describe "#amount_for_rental" do
      it "charges extra if rental days exceeded" do
        category       = described_class.new
        additonal_days = 2
        rented_at      = Date.today - (described_class::RENTAL_DAYS + additonal_days)
        
        expect(category.amount_for_rental(rented_at)).to eql  described_class::PRICE_AMOUNT + (described_class::EXTRA_PRICE * additonal_days)
      end
  
      it "charges normal price amount if within rental days" do
        category       = described_class.new
        rented_at      = Date.today - (described_class::RENTAL_DAYS - 1)      
        expect(category.amount_for_rental(rented_at)).to eql  described_class::PRICE_AMOUNT
      end
    end
  end
  
  describe Movie do
    describe "#category" do
      it "belongs to a category" do
        expect(movie.category.is_a?(RegularCategory)).to be_truthy
      end

      it "gets its price from the category" do
        expect(movie.price).to eql movie.category.price_amount
      end
    end
  end
end

# SEED some data to print out a statement
customer = Customer.new(name: "Bob")
customer.add_rental Movie.new(title: "Mad Max", category: RegularCategory.new), (Date.today - 4)  # rented Regular movie (2 day extra charge)
customer.add_rental Movie.new(title: "Dune", category: NewReleaseCategory.new), (Date.today - 10) # rented new Release movie (no extra charge)
customer.add_rental Movie.new(title: "Babe", category: ChildrensCategory.new), (Date.today - 4)   # rented a childrens movie (1 day extra charge)

customer.statement
