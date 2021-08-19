require_relative "../config/environment.rb"
#Require the config envrionment of this wont work

#class Dog = table named dogs - table will be PLURAL, class will be SINGULAR
class Dog

    #attr_accessors are the columns that will be in the dogs table
    attr_accessor :name, :breed, :id

    #initialize everything like normal - these will not be saved into db until saved
    def initialize(id: nil, name:, breed:)
        @id = id 
        @name = name
        @breed = breed
    end 

    #This is the standard for creating a table - DO NOT PRESS ENTER AFTER "SQL" OR YOU WILL GET A SYNTAX ERROR
    #"sql=" can be whatever you want to call it but note that it goes in the execution line
    def self.create_table
        sql = <<-SQL
          CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT,
            breed TEXT
            )
        SQL
        DB[:conn].execute(sql)
    end


    #standard drop table 
    def self.drop_table
        sql = "DROP TABLE IF EXISTS dogs"
        DB[:conn].execute(sql)
    end 


    #This is when something will actually be saved into the database - if the instance id matches something already in the db, update it
    #if it is the first time being saved, insert the columns into the table with the values as bound parameters
    #SQL - DO NOT PRESS ENTER AFTER THIS OR ELSE THE SYNTAX WONT WORK
    #connect to the db and execute the sql, then insert the instance columns (self.name, self.breed)
    #set the last_insert_rowid() [0]- last inserted row, [0]- id is the first item in array
    #return itself after saving 
    #This will be a standard save method
    def save 
        if self.id 
            self.update 
        else 
            sql = <<-SQL 
                INSERT INTO dogs (name, breed)
                VALUES (?, ?)
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
        end 
        self 
    end 


    #create a new instance - this will be pretty standard - save the instance, return the newly created instance
    def self.create(name:, breed:)
        dog = Dog.new(name: name, breed: breed)
        dog.save
        dog
    end


    #in order to update something you have to find it first, if its not there, create it
    #Look to see if the table is empty based on the id - if the id is not there, create it
    #When two dogs have the same name and different breed, it returns the correct dog
    #When creating a new dog with the same name as persisted dogs, it returns the correct dog
    def self.find_or_create_by(name:, breed:)
        sql = <<-SQL 
            SELECT *
            FROM dogs 
            WHERE name = ?
            AND breed = ?
            LIMIT 1
        SQL
        dog = DB[:conn].execute(sql,name,breed)

        if !dog.empty?
            dog_data = dog[0]
            dog = Dog.new(id: dog_data[0], name: dog_data[1], breed: dog_data[2])
        else  
            dog = self.create(name: name, breed: breed)
        end 
        dog 
    end 


    #creates an instance with corresponding attribute values
    def self.new_from_db(row)
        id = row[0]
        name = row[1]
        breed = row[2]
        self.new(id: id, name: name, breed:breed)
    end 


    #Write a sql query that returns an instance of dog that matches the name from the db
    #when looking for somehthing (finding something) use the .map function
    #.map returns a new array containing the values returned by the block
    def self.find_by_name(name)
        sql = <<-SQL  
            SELECT *
            FROM dogs 
            WHERE name = ?
            LIMIT 1 
        SQL
        
        DB[:conn].execute(sql,name).map do |row|
            self.new_from_db(row)
        end.first
    end 


    #Returns a new dog object by ID - find a particular dogs id
    #When finding something iterate over it using .map 
    def self.find_by_id(id)
        sql = <<-SQL 
            SELECT *
            FROM dogs 
            WHERE id = ?
            LIMIT 1
        SQL

        DB[:conn].execute(sql,id).map do |row|
            self.new_from_db(row)
        end.first 
    end 

 
    #This will be standard, use bound parameters to prevent SQL injections
    def update 
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end 


end
