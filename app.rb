require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative './model.rb'


enable :sessions

unProtectedRoutes = ['/', '/register', '/showlogin', '/laws', '/log_out', '/laws/:id']

before do
  path = request.path_info
  pathMethod = request.request_method
  pathInclude = unProtectedRoutes.include?(path)

  if  not pathInclude and request.path_info != '/error' and request.path_info != '/login/error' and request.path_info != '/login/unmatched' and request.path_info != '/laws/error' and pathMethod == "GET"
    if session[:id] == []
      redirect('/error')
    end
  end
  
end

get('/')  do
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  prime_minister = db.execute("SELECT username FROM user WHERE access = ?", 1).first
  slim(:"hem", locals:{prime_minister:prime_minister})
end 

get('/showlogin') do
  session[:id] = []
  session[:user_access] = []
  slim(:login)
end

get('/authorised') do 
  slim(:authorised)
end

get('/error') do
  slim(:error)
end

get('/login/error') do
  session[:id] = []
  session[:user_access] = []
  slim(:login_error)
end

get('/login/unmatched') do
  slim(:login_unmatched)
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM user WHERE username = ?", username)

  if result.empty?
    redirect('/login/error')
  end  

  password_digest= result.first["password"]
  id = result.first["id"]
  access = result.first["access"]

  if BCrypt::Password.new(password_digest) == password
    session[:id] = id
    session[:user_access] = access
    redirect('/all_laws')

  else
    redirect('/login/error')
  end
end

get('/log_out') do
  session[:id] = []
  session[:user_access] = []
  slim(:"log_out")
end

get ('/register') do
  slim(:register)
end

get ('/register/error') do
  slim(:register_error)
end

post('/user/new') do
  username = params[:username]
  access = params[:access]
  password = params[:password]
  password_confirm = params[:password_confirm]
  access = params[:access]

  db = SQLite3::Database.new('db/laws.db')
  result=db.execute("SELECT id FROM user WHERE username = ?", username)
  if result.empty?
    if (password==password_confirm)
      password_digest = BCrypt::Password.create(password)
  
      db.execute("INSERT INTO user (username, password, access) VALUES (?, ?, ?)", username, password_digest, access)
      redirect('/')

    else
      redirect('/register/error')
    end

  else
    redirect('/showlogin')
  end
end






get('/ministers') do 
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  all_users = db.execute("SELECT * FROM user")
  slim(:"ministers/index", locals:{all_users:all_users})
end

get('/ministers/:id') do 
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM user WHERE id = ?", id).first
  district = db.execute("SELECT district_name FROM district WHERE access IN (SELECT access FROM user WHERE id = ?)", id).first
  slim(:"ministers/show", locals:{result:result, district:district})
end

post('/ministers/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  db.execute("DELETE FROM user WHERE id = ?", id)
  redirect('/ministers')
end

get('/ministers/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  user_info = db.execute("SELECT * FROM user WHERE id = ?", id).first
  slim(:"/ministers/edit", locals:{user_info:user_info})
end

post('/ministers/:id/update') do 
  id = params[:id].to_i
  name = params[:name]
  access = params[:access]
  db = SQLite3::Database.new('db/laws.db')
  db.execute("UPDATE user SET username = ?, access = ? WHERE id = ?", name, access, id)
  redirect('/ministers') 
end






get('/laws') do
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM laws")
  slim(:"laws/index", locals:{the_laws:result})
end

get('/all_laws') do
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM laws")
  slim(:"laws/index_loged_in", locals:{the_laws:result})
end

get('/laws/error') do
  slim(:"/laws/errors")
end

before('/laws/new') do
  if session[:user_access] == 1
    redirect('/laws/add')
  elsif session[:user_access] == []
    redirect('/error')
  end
  
end

get('/laws/new') do
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT district_name FROM district WHERE access = ?", session[:user_access]).first
  slim(:"laws/new", locals:{result:result})
end

post('/laws/new') do
  law_name = params[:law_name]
  description = params[:description]
    
  time = Time.new
  time2 = time.to_s

  db = SQLite3::Database.new('db/laws.db')
  district_name = db.execute("SELECT district_name FROM district WHERE access = ?", session[:user_access])
  access_number = session[user_access]
  maybe_dubble=db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name)
  
  if maybe_dubble.empty?
    db.execute("INSERT INTO laws (law_name, description, updated) VALUES (?,?,?)", law_name, description, time2)
    db.execute("INSERT INTO district (district_name, access) VALUES (?,?)", district_name, access_number)
    law_id = db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name).first.first
    district_id = db.execute("SELECT district_id FROM district WHERE district_name = ?", district_name).first.first
    db.execute("INSERT INTO law_district_relation (law_id, district_id, updated) VALUES (?, ?, ?)", law_id, district_id, time2)
    redirect('/all_laws')
  else
    redirect('laws/error')
  end

end

get('/laws/add') do
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  all_districtnames = db.execute("SELECT * FROM district")
  slim(:"laws/add", locals:{all_districtnames:all_districtnames})
end 

post('/laws/add') do
  law_name = params[:law_name]
  description = params[:description]
  district_name = params[:district_name]
  district_name2 = params[:district_name2]
  district_name3 = params[:district_name3]
  access_number = params[:access_number]
  access_number2 = params[:access_number2]
  access_number3 = params[:access_number3]
  time = Time.new
  time2=time.to_s

  db = SQLite3::Database.new('db/laws.db')
  maybe_dubble=db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name)
  if maybe_dubble.empty?
    db.execute("INSERT INTO laws (law_name, description, updated) VALUES (?,?,?)", law_name, description, time2)

    if district_name != ""
      db.execute("INSERT INTO district (district_name, access) VALUES (?,?)", district_name, access_number)
      law_id = db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name).first.first
      district_id = db.execute("SELECT district_id FROM district WHERE district_name = ?", district_name).first.first
      db.execute("INSERT INTO law_district_relation (law_id, district_id, updated) VALUES (?, ?, ?)", law_id, district_id, time2)
    end
    
    if district_name2 != "" || access_number2 != "" 

      db.execute("INSERT INTO district (district_name, access) VALUES (?,?)", district_name2, access_number2)
      law_id = db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name).first.first
      district_id = db.execute("SELECT district_id FROM district WHERE district_name = ?", district_name2).first.first
      db.execute("INSERT INTO law_district_relation (law_id, district_id, updated) VALUES (?, ?, ?)", law_id, district_id, time2)
    end

    if district_name3 != ""  || access_number3 != "" 
      db.execute("INSERT INTO district (district_name, access) VALUES (?,?)", district_name3, access_number3)
      law_id = db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name).first.first
      district_id = db.execute("SELECT district_id FROM district WHERE district_name = ?", district_name3).first.first
      db.execute("INSERT INTO law_district_relation (law_id, district_id, updated) VALUES (?, ?, ?)", law_id, district_id, time2)
    end

    redirect('/all_laws')
  else
      redirect('laws/error')
  end
end

get('/laws/add_district') do
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM laws")
  result2 = db.execute("SELECT * FROM district")
  slim(:"laws/add_law's_district", locals:{the_laws:result, the_district:result2})
end

get('/laws/:id/edit') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM laws WHERE law_id = ?", id).first
  result2 = db.execute("SELECT * FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id).first
  slim(:"/laws/edit", locals:{result:result, result2:result2})
end

get('/laws/:id') do 
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM laws WHERE law_id = ?", id).first
  all_districts = db.execute("SELECT * FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id)
  responseble = db.execute("SELECT username FROM user WHERE access IN (SELECT access FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?))", id)
  slim(:"laws/show", locals:{result:result, all_districts:all_districts, responseble:responseble})
end

post('/laws/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  district_access = db.execute("SELECT access FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id).first
  if session[:user_access] == district_access || session[:user_access] == 1
    db.execute("DELETE FROM laws WHERE law_id = ?", id)
    db.execute("DELETE FROM law_district_relation WHERE law_id = ?", id)
    redirect('/all_laws')
  else 
    redirect('/authorised')
  end
end

post('/laws/:id/update') do 
  id = params[:id].to_i
  name = params[:name]
  description = params[:description]
  db = SQLite3::Database.new('db/laws.db')
  district_access = db.execute("SELECT access FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id).first
  if session[:user_access] == district_access || session[:user_access] == 1
    db.execute("UPDATE laws SET law_name = ?, description = ? WHERE law_id = ?", name, description, id)
    redirect('/all_laws')
    #db.execute("UPDATE district SET district_name = ?", ) 
  else
    redirect('/authorised')
  end
end











get('/districts') do
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM district")
  slim(:"districts/index", locals:{the_districts:result})
end


get('/districts/new') do
  slim(:"districts/new")
end

get('/districts/error') do
  slim(:"districts/error")
end

post('/districts/new') do
  district_name = params[:district_name]
  access_number = params[:access_number]

  db = SQLite3::Database.new('db/laws.db')
  maybe_dubble=db.execute("SELECT district_id FROM district WHERE district_name = ?", district_name)
  if maybe_dubble.empty?
      db.execute("INSERT INTO district (district_name, access) VALUES (?,?)", district_name, access_number)
  else
    redirect('districts/error')
  end
end

get('/districts/:id/edit') do
  id = params[:id].to_i

  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM district WHERE district_id = ?", id).first
  slim(:"/districts/edit", locals:{result:result})
end

post('/districts/:id/update') do 
  id = params[:id].to_i
  name = params[:name]
  access = params[:access]
  db = SQLite3::Database.new('db/laws.db')
  district_access = db.execute("SELECT access FROM district WHERE district_id = ?", id)

  if session[:user_access] == district_access || session[:user_access] == 1
    db.execute("UPDATE district SET district_name = ?, access = ? WHERE district_id = ?", name, access, id)
    redirect('/districts')
  else
    redirect('/authorised')
  end
end

post('/districts/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  district_access = db.execute("SELECT access FROM district WHERE district_id = ?", id)

  if session[:user_access] == district_access || session[:user_access] == 1
    db.execute("DELETE FROM district WHERE district_id = ?", id)
    db.execute("DELETE FROM law_district_relation WHERE district_id = ?", id)
    redirect('/districts')
  else 
    redirect('/authorised')
  end
end

get('/districts/:id') do 
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM district WHERE district_id = ?", id).first
  all_districts_law = db.execute("SELECT * FROM laws WHERE law_id IN (SELECT law_id FROM law_district_relation WHERE district_id = ?)", id)
  slim(:"districts/show", locals:{result:result, laws_of_district:all_districts_law})
end 