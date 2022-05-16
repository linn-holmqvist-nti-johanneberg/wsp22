require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

def database(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true 
    return db
end

def is_it_empty(user_input)
    if user_input.empty?
        return true
    end 
end

def long(user_input)
   if user_input < 2 or user_input > 70
        return true
   end
end

def security(unProtectedRoutes)
    path = request.path_info
    pathMethod = request.request_method
    pathInclude = unProtectedRoutes.include?(path)
    
  if  not pathInclude and request.path_info != '/error' and request.path_info != '/login/error' and request.path_info != '/login/unmatched' and request.path_info != '/laws/error' and pathMethod == "GET"
    if session[:id] == []
      return true
    else
        return false
    end

  end
end

def hem()
    db = database('db/laws.db') 
    prime_minister = db.execute("SELECT username FROM user WHERE access = ?", 1).first
    return prime_minister
end

def login(username, password)
    db = database('db/laws.db') 
    result = db.execute("SELECT * FROM user WHERE username = ?", username)
    return result
end

def samepw(pw, pwc)
    if pw == pwc
        return true
    else
        return false
    end
end

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

def all_users()
    db = database('db/laws.db')
    all_users = db.execute("SELECT * FROM user")
    return all_users
end

def a_minister(id)
    db = database('db/laws.db')
    result = db.execute("SELECT * FROM user WHERE id = ?", id).first
    return result
end

def a_ministers_district(id)
    db = database('db/laws.db')
    district = db.execute("SELECT district_name FROM district WHERE access IN (SELECT access FROM user WHERE id = ?)", id).first
    return district
end

def minister_delete(id)
    db = database('db/laws.db')
    db.execute("DELETE FROM user WHERE id = ?", id)
end

def minister_edit(id)
    db = database('db/laws.db')
    user_info = db.execute("SELECT * FROM user WHERE id = ?", id).first
    return user_info
end

def minister_update(name, access, id)
    db = SQLite3::Database.new('db/laws.db')
    db.execute("UPDATE user SET username = ?, access = ? WHERE id = ?", name, access, id)
end

def all_laws()
    db = database('db/laws.db')
    result = db.execute("SELECT * FROM laws")
    return result
end

def law_create()
    db = database('db/laws.db')
    a_districtname = db.execute("SELECT district_name FROM district WHERE access = ?", session[:user_access]).first
    district_names = db.execute("SELECT * FROM district")
    return a_districtname, district_names
end

def no_double(law_name)
    db = database('db/laws.db')
    maybe_dubble=db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name)
    if maybe_dubble.empty?
        return true
    else 
        return false
    end
end

def law_new_president(law_name, description, time)
    db = database('db/laws.db')
    db.execute("INSERT INTO laws (law_name, description, updated) VALUES (?,?,?)", law_name, description, time)
end

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

def new_law_ministers(law_name, description, time)
    db = database('db/laws.db')
    district_name = db.execute("SELECT district_name FROM district WHERE access = ?", session[:user_access]).first
    db.execute("INSERT INTO laws (law_name, description, updated) VALUES (?,?,?)", law_name, description, time)
    return district_name
end    

def new_law_ministers_part2(law_name, time, district_name)
    db = database('db/laws.db')
    law_id = db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name).first
    law_id = law_id["law_id"]
    district_id = db.execute("SELECT district_id FROM district WHERE district_name = ?", district_name).first
    district_id = district_id["district_id"]
    db.execute("INSERT INTO law_district_relation (law_id, district_id, updated) VALUES (?, ?, ?)", law_id, district_id, time)

end

def laws_edit(id)
    db = database('db/laws.db')
    all_info_law = db.execute("SELECT * FROM laws WHERE law_id = ?", id).first
    all_info_district = db.execute("SELECT * FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id)
    all_info_district1 = all_info_district[0]
    all_info_district2 = all_info_district[1]
    all_info_district3 = all_info_district[2]

    return all_info_law, all_info_district1, all_info_district2, all_info_district3
end

def laws_update(id, name, description)
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


    if session[:user_access] == district_access1 || session[:user_access] == district_access2 || session[:user_access] == district_access3 || session[:user_access] == 1
        db.execute("UPDATE laws SET law_name = ?, description = ? WHERE law_id = ?", name, description, id)
        return district_access1, district_access2, district_access3
    else
        return false
    end
end

def law_update_president(district_name, district_access)
    db = database('db/laws.db')
    db.execute("UPDATE district SET district_name = ? WHERE access = ?", district_name, district_access)
end

def laws_id(id)
    db = database('db/laws.db')
    law_info = db.execute("SELECT * FROM laws WHERE law_id = ?", id).first
    district_info = db.execute("SELECT * FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id)
    minister_info = db.execute("SELECT username FROM user WHERE access IN (SELECT access FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?))", id)
    return law_info, district_info, minister_info
end

def laws_delete(id)
    db = database('db/laws.db')
    district_access = db.execute("SELECT access FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id).first
    if session[:user_access] == district_access || session[:user_access] == 1
        db.execute("DELETE FROM laws WHERE law_id = ?", id)
        db.execute("DELETE FROM law_district_relation WHERE law_id = ?", id)
        return true
    else 
        return false
    end
end

def district()
    db = database('db/laws.db')
    result = db.execute("SELECT * FROM district")
    return result
end

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

def district_edit(id)
    db = database('db/laws.db')
    district_info = db.execute("SELECT * FROM district WHERE district_id = ?", id).first
    return district_info
end

def district_update(id, name, access)
    db = database('db/laws.db')
    
    if session[:user_access] == access || session[:user_access] == 1
        db.execute("UPDATE district SET district_name = ?, access = ? WHERE district_id = ?", name, access, id)
        return true
    else
        return false
    end
end

def district_delete(id)
    db = database('db/laws.db')
    district_access = db.execute("SELECT access FROM district WHERE district_id = ?", id)

    if session[:user_access] == district_access || session[:user_access] == 1
        db.execute("DELETE FROM district WHERE district_id = ?", id)
        db.execute("DELETE FROM law_district_relation WHERE district_id = ?", id)
        return true
    else 
        return false
    end
end

def a_district(id)
    db = database('db/laws.db')
    district_info = db.execute("SELECT * FROM district WHERE district_id = ?", id).first
    all_districts_law = db.execute("SELECT * FROM laws WHERE law_id IN (SELECT law_id FROM law_district_relation WHERE district_id = ?)", id)
    return district_info, all_districts_law
end