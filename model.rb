require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'



module Model    

    # Attempts to open a new database connection
    #
    # @oaram [String] path, the path to database
    #
    # @return [Array] containing all the data from the database
    def database(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true 
        return db
    end

    # Attempts to check if the user's input is empty
    #
    # @oaram [String] path, input from user 
    #
    # @return [Boolean] whether input from user is to long
    def is_it_empty(user_input)
        if user_input.empty?
            return true
        end 
    end

    # Attempts to check length of the user's input
    #
    # @oaram [String] path, input from user 
    #
    # @return [Boolean] whether input from user is to long
    def long(user_input)
        if user_input.length < 2 or user_input.length > 70
            return true
        end
        
    end

    # Attempts to check if the user is loged in
    # 
    # @oaram [Array] unProtectedRoutes, list of all sites there should be visible for everyone
    # @oaram [Integer] user_access_number, access number from user 
    # 
    # @return [Boolean] whether the are loged in
    def security(unProtectedRoutes, user_access_number)
        path = request.path_info
        pathMethod = request.request_method
        pathInclude = unProtectedRoutes.include?(path)
        
        if  not pathInclude and request.path_info != '/error' and request.path_info != '/login/error' and request.path_info != '/login/unmatched' and request.path_info != '/laws/error' and pathMethod == "GET"
            if user_access_number  == []
                return true
            else
                return false
            end

        end
    end

    # Finds name from table users
    # 
    # @see Model#database
    #
    # @return [String] the name of the user with access number 1
    def hem()
        db = database('db/laws.db') 
        prime_minister = db.execute("SELECT username FROM user WHERE access = ?", 1).first
        return prime_minister
    end

    # Attempts to find a user
    #
    # @params [String] username, username from user
    # @params [String] password, password from user
    # @see Model#database
    #
    # @return [Array] information about the user
    def login(username, password)
        db = database('db/laws.db') 
        result = db.execute("SELECT * FROM user WHERE username = ?", username)
        return result
    end

    # Atempts to check if två inputs are the same
    #
    # @params [String] password, password from input
    # @params [String] password, confirm password from input
    #
    # @return [boolean] whether the two params are the same
    def samepw(pw, pwc)
        if pw == pwc
            return true
        else
            return false
        end
    end


    # Attempts to create a new user
    # 
    # @params [String] username, username from user
    # @params [Integer] access, access from user
    # @params [String] password, password from user
    # @params [String] password_confirm, password confirmed from user
    # @see Model#database
    # @see Model#samepw
    #
    # return [boolean]
    #   * whether the user allready exist
    #   * whether an error ocurred
    def register(username, access, password, password_confirm)
        db = database('db/laws.db')
        result=db.execute("SELECT id FROM user WHERE username = ?", username)
        
        if result.empty?
            if samepw(password, password_confirm)
                password_digest = BCrypt::Password.create(password)
                db.execute("INSERT INTO user (username, password, access) VALUES (?, ?, ?)", username, password_digest, access)
                return true 

            else 
                return false
            end
        
        else
            return false
        end
    end

    # Attemps to check if primeminister uses a bot or hacker to create new users
    #
    # @params [Interger] time_before, time when the latest user was created
    #
    # @return [Boolean] whether the time between to users was created is longer than 1.5
    def cool_down(time_before)
        tidskillnad = Time.now.to_i - time_before
        return tidskillnad < 1.5
    end

    # Finds all data from table users
    #
    # @see Model#database
    #
    # @return [Array] list of all info from table users
    def all_users()
        db = database('db/laws.db')
        all_users = db.execute("SELECT * FROM user")
        return all_users
    end

    # Finds data from id from table users 
    #
    # @params [Interger] id, id from log in user
    # @see Model#database
    #
    # @return [Array] list of all data from id from table users
    def a_minister(id)
        db = database('db/laws.db')
        result = db.execute("SELECT * FROM user WHERE id = ?", id).first
        return result
    end

    # Finds data about the name  the district the user has 
    #
    # @params [Interger] id, id from log in user
    # @see Model#database
    #
    # @return [String] the name of the district the user has
    def a_ministers_district(id)
        db = database('db/laws.db')
        district = db.execute("SELECT district_name FROM district WHERE access IN (SELECT access FROM user WHERE id = ?)", id).first
        return district
    end

    # Attempts to delete a row from the ministers table
    #
    # @params [Interger] id, id from log in user
    # @see Model#database

    def minister_delete(id)
        db = database('db/laws.db')
        db.execute("DELETE FROM user WHERE id = ?", id)
    end

    # Finds a row from user table
    #
    # @params [Interger] id, id from log in user
    # @see Model#database
    #
    # @return [Array] list with all data from log in user
    def minister_edit(id)
        db = database('db/laws.db')
        user_info = db.execute("SELECT * FROM user WHERE id = ?", id).first
        return user_info
    end

    # Attempts to update a row from the ministers table
    #
    # @params [String] name, name from input from user
    # @params [Interger] access, access number from input from user
    # @params [Interger] id, id from input from user
    # @see Model#database
    def minister_update(name, access, id)
        db = SQLite3::Database.new('db/laws.db')
        db.execute("UPDATE user SET username = ?, access = ? WHERE id = ?", name, access, id)
    end

    # Find all laws
    #
    # @see Model#database
    #
    # @return [Array] list of all data from table laws
    def all_laws()
        db = database('db/laws.db')
        result = db.execute("SELECT * FROM laws")
        return result
    end

    # Finds districtname from the district table and all data from the district table
    #
    # @params [Integer] user_access_number, access number of log in user
    # @see Model#database
    #
    # @ return [Hash] 
    #   * :district_name [String] a_districtname, districtname from the district table
    #   * :district _info [String] district_names, all data from the district table
    def law_create(user_access_number)
        db = database('db/laws.db')
        a_districtname = db.execute("SELECT district_name FROM district WHERE access = ?", user_access_number).first
        district_names = db.execute("SELECT * FROM district")
        return a_districtname, district_names
    end

    # Attempts to find a law 
    #
    # @params [String] law_name, the name of the law that trys to check if already exists
    # @see Model#database
    # 
    # @return [Boolean] whether something already exist
    def no_double(law_name)
        db = database('db/laws.db')
        maybe_dubble=db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name)
        if maybe_dubble.empty?
            return true
        else 
            return false
        end
    end

    # Attempts to insert a new row in the laws table
    #
    # @params [String] law_name, the name of the new law 
    # @params [String] description, the description of the new law 
    # @params [String] time, the time the new law creates
    # @see Model#database
    def law_new_president(law_name, description, time)
        db = database('db/laws.db')
        db.execute("INSERT INTO laws (law_name, description, updated) VALUES (?,?,?)", law_name, description, time)
    end

    # Attempts to insert a new row in the district table and in the law_district_relation table 
    #
    # @params [String] law_name, name of the new law
    # @params [String] disrict_name, name of the district
    # @params [Integer] access, access number of the district
    # @params [String] time, the time the new law creates
    # @see Model#database
    def enter_new_lawdistrict(law_name, district_name, access_number, time)
        db = database('db/laws.db')
        maybe_dubble = db.execute("SELECT district_name FROM district WHERE access = ?", access_number).first
        maybe_dubble = maybe_dubble["district_name"]
        
        if district_name != "" || access_number != ""
            if district_name != maybe_dubble
                db.execute("INSERT INTO district (district_name, access) VALUES (?,?)", district_name, access_number)
            end
            law_id = db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name).first
            law_id = law_id["law_id"]
            district_id = db.execute("SELECT district_id FROM district WHERE district_name = ?", district_name).first
            district_id = district_id["district_id"]
            db.execute("INSERT INTO law_district_relation (law_id, district_id, updated) VALUES (?, ?, ?)", law_id, district_id, time) 
        end
    end

    # Attempts to insert a new row in the laws table
    #
    # @params [String] law_name, name of the new law
    # @params [String] description, description of the new law    
    # @params [String] time, the time the new law creates
    # @params [Integer] user_access_number, access number of the user
    # @see Model#database
    #
    # @return [String] district_name, name of the district
    def new_law_ministers(law_name, description, time, user_access_number)
        db = database('db/laws.db')
        district_name = db.execute("SELECT district_name FROM district WHERE access = ?", user_access_number).first
        db.execute("INSERT INTO laws (law_name, description, updated) VALUES (?,?,?)", law_name, description, time)
        return district_name
    end    

    # Attemps to insert a new row in the law_district_relation table 
    #
    # @params [String] law_name, name of the new law
    # @params [String] time, the time the new law creates
    # @params [String] district_name, name of the district
    # @see Model#database
    def new_law_ministers_part2(law_name, time, district_name)
        db = database('db/laws.db')
        law_id = db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name).first
        law_id = law_id["law_id"]
        district_id = db.execute("SELECT district_id FROM district WHERE district_name = ?", district_name).first
        district_id = district_id["district_id"]
        db.execute("INSERT INTO law_district_relation (law_id, district_id, updated) VALUES (?, ?, ?)", law_id, district_id, time)
    end

    # Finds data from the tables; district and users
    #
    # @params [Integer] id, id from site
    # @see Model#database
    #
    # @return [Hash]
    # * :all_info_law [Array] list with all info of a law from law table
    # * :all_info_district1 [Array] list with all district of a law from district table
    # * :all_info_district2 [Array] list with all district of a law from district table
    # * :all_info_district3 [Array] list with all district of a law from district table
    def laws_edit(id)
        db = database('db/laws.db')
        all_info_law = db.execute("SELECT * FROM laws WHERE law_id = ?", id).first
        all_info_district = db.execute("SELECT * FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id)
        all_info_district1 = all_info_district[0]
        all_info_district2 = all_info_district[1]
        all_info_district3 = all_info_district[2]

        return all_info_law, all_info_district1, all_info_district2, all_info_district3
    end

    # Attempts to update a row in the law table
    #
    # @params [Integer] id, id of the choosen law
    # @params [String] name, name of the new law
    # @params [String] description, description of the new law    
    # @params [Integer] user_access_number, access number of the user
    # @see Model#database
    #
    # @return [Hash]
    # * :district_access1 access number of the first district 
    # * :district_access2 access number of the second district 
    # * :district_access3 access number of the third district 

    def laws_update(id, name, description, user_access_number)
        db = database('db/laws.db')

        all_access_districts = db.execute("SELECT access FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id)

        if all_access_districts[0] == nil
            district_access1 = ""
        else
            district_access1 = all_access_districts[0].first
            district_access1 = district_access1[1]
        end    

        if all_access_districts[1] == nil
            district_access2 = ""
        else
            district_access2 = all_access_districts[1].first
            district_access2 = district_access2[1]
        end   
        
        if all_access_districts[2] == nil
            district_access3 = ""
        else
            district_access3 = all_access_districts[2].first
            district_access3 = district_access3[1]
        end    

        if user_access_number == district_access1 || user_access_number == district_access2 || user_access_number == district_access3 || user_access_number == 1
            db.execute("UPDATE laws SET law_name = ?, description = ? WHERE law_id = ?", name, description, id)
            return district_access1, district_access2, district_access3
        else
            return false
        end
    end

    # Attempts to update a row in the district table
    #
    # @params [String] disrict_name, name of the district
    # @params [Interger] district_access, access of the district 
    # @see Model#database
    def law_update_president(district_name, district_access)
        db = database('db/laws.db')
        db.execute("UPDATE district SET district_name = ? WHERE access = ?", district_name, district_access)
    end

    # Find all data from a law, a distrikt and a user
    #
    # @params [String] disrict_name, name of the district
    # @params [Interger] id, id of the law
    # @see Model#database
    #
    # @return [Hash]
    # * :law_info all data from a law
    # * :district_info access all data from a district 
    # * :minister_info access all data from a user 
    def laws_id(id)
        db = database('db/laws.db')
        law_info = db.execute("SELECT * FROM laws WHERE law_id = ?", id).first
        district_info = db.execute("SELECT * FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id)
        minister_info = db.execute("SELECT username FROM user WHERE access IN (SELECT access FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?))", id)
        return law_info, district_info, minister_info
    end

    # Attempts to delete a row from the laws table
    #
    # @params [Integer] id, id from the website
    # @params [Interger] user_access_number, id from log in user
    # @see Model#database
    def laws_delete(id, user_access_number)
        db = database('db/laws.db')
        district_access = db.execute("SELECT access FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id).first
        if user_access_number == district_access || user_access_number == 1
            db.execute("DELETE FROM laws WHERE law_id = ?", id)
            db.execute("DELETE FROM law_district_relation WHERE law_id = ?", id)
            return true
        else 
            return false
        end
    end

    # Find all districts
    #
    # @see Model#database
    #
    # @return [Array] list of all data from table district
    def district()
        db = database('db/laws.db')
        result = db.execute("SELECT * FROM district")
        return result
    end

    # Attempts to insert a new row in the district table
    #
    # @params [String] district_name, the name of the district
    # @params [Integer] access_number, the access number of the district
    #
    # @return [Boolean] whether there already is a law with same name
    def district_new(district_name, access_number)
        db = database('db/laws.db')
        maybe_dubble=db.execute("SELECT district_id FROM district WHERE district_name = ?", district_name)
        if maybe_dubble.empty?
            db.execute("INSERT INTO district (district_name, access) VALUES (?,?)", district_name, access_number)
            return true
        else 
            return false
        end
    end

    # Finds data from the district table
    #
    # @params [Integer] id, id from website
    # @see Model#database
    #
    # @return [Array] all data from a district
    def district_edit(id)
        db = database('db/laws.db')
        district_info = db.execute("SELECT * FROM district WHERE district_id = ?", id).first
        return district_info
    end

    # Attempts to update a row in the district table
    #
    # @params [Integer] id, id of the choosen district
    # @params [String] name, name of the new district
    # @params [Integer] access, access number from the district
    # @params [Integer] user_access_number, access number of the user
    # @see Model#database
    #
    # @return [Boolean] whether to update

    def district_update(id, name, access, user_access_number)
        db = database('db/laws.db')
        
        if user_access_number == access || user_access_number == 1
            db.execute("UPDATE district SET district_name = ?, access = ? WHERE district_id = ?", name, access, id)
            return true
        else
            return false
        end
    end

    # Attempts to delete a row from the district table
    #
    # @params [Integer] id, id from the website
    # @params [Interger] user_access_number, id from log in user
    # @see Model#database
    #
    # @return [Boolean] whether to update
    def district_delete(id, user_access_number)
        db = database('db/laws.db')
        district_access = db.execute("SELECT access FROM district WHERE district_id = ?", id)

        if user_access_number == district_access || user_access_number == 1
            db.execute("DELETE FROM district WHERE district_id = ?", id)
            db.execute("DELETE FROM law_district_relation WHERE district_id = ?", id)
            return true
        else 
            return false
        end
    end

    # Find all data from a law, a district and a user
    #
    # @params [Interger] id, id of the law
    # @see Model#database
    #
    # @return [Hash]
    # * :district_info access all data from a district 
    # * :all_districts_law  all data from the laws that has same a district
    def a_district(id)
        db = database('db/laws.db')
        district_info = db.execute("SELECT * FROM district WHERE district_id = ?", id).first
        all_districts_law = db.execute("SELECT * FROM laws WHERE law_id IN (SELECT law_id FROM law_district_relation WHERE district_id = ?)", id)
        return district_info, all_districts_law
    end
end

