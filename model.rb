require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

def database(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true 
    return db
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
    db = SQLite3::Database.new('db/laws.db')
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

