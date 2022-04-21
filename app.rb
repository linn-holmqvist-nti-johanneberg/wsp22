require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions


get('/')  do
  slim(:hem)
end 

get('/showlogin') do
  slim(:login)
end

get('/error') do
  slim(:error)
end

get('/login/error') do
  slim(:login_error)
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT username, password FROM user WHERE username = ?", username).first

  if result.empty?
    redirect('/login/error')
  end  
  
  password_digest= result["password"]
  id = result["id"]

  if BCrypt::Password.new(password_digest) == password
    session[:id] = id
    redirect('/all_laws')
  else
    redirect('/login/error')
  end
end

get('/log_out') do
  session[:id] = []
  slim(:log_out)
end

get ('/register') do
  slim(:register)
end

post('/user/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  access = params[:access]

  db = SQLite3::Database.new('db/laws.db')
  result=db.execute("SELECT id FROM user WHERE user = ?", user)
  if result.empty?
    if (password==password_confirm)
      password_digest = BCrypt::Password.create(password)
  
      db.execute("INSERT INTO user (username, password, access) VALUES (?, ?, ?)", username, password_digest, 1)
      redirect('/')

    else
      "Lösenorden matchar inte! Testa igen"
    end

  else
    redirect('/login')
  end
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
  slim(:"laws/index_login", locals:{the_laws:result})
end

get('/laws/error') do
  slim(:"/laws/errors")
end

get('/laws/new') do
  slim(:"laws/new")
end

get('/laws/add_district') do
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM laws")
  result2 = db.execute("SELECT * FROM district")
  slim(:"laws/add_district", locals:{the_laws:result, the_district:result2})
end

post('/laws/new') do
  law_name = params[:law_name]
  description = params[:description]
  district_name = params[:district_name]
  access_number = params[:access_number].to_i

  db = SQLite3::Database.new('db/laws.db')
  maybe_dubble=db.execute("SELECT law_id FROM laws WHERE law_name = ?", law_name)
  if maybe_dubble.empty?
    # ta med id:t för submitknappen
      db.execute("INSERT INTO laws (law_name, description) VALUES (?,?)", law_name, description)
      db.execute("INSERT INTO district (district_name, access) VALUES (?,?)", district_name, access_number)
      #if submitknappen was pressed
      #  redirect('/laws')
      #else
        #redirect('/laws/add_district')
      #end
  else
    redirect('laws/error')
  end
  

  
end

post('/laws/:id/delete') do
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.execute("DELETE FROM laws WHERE law_id = ?", id)
  redirect('/laws')
end

post('/laws/:id/update') do 
  id = params[:id].to_i
  name = params[:name]
  description = params[:description]
  db = SQLite3::Database.new('db/laws.db')
  db.execute("UPDATE laws SET law_name = ?, description = ? WHERE law_id = ?", name, description, id)
  #db.execute("UPDATE district SET district_name = ?", ) 
  redirect('/all_laws')
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
  result2 = db.execute("SELECT district_name FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id).first
  slim(:"laws/show", locals:{result:result,result2:result2})
end

before do
# kan det vara att den inte hittar id?
  p request.path_info
  p session[:id]
  if session[:id] == nil && request.path_info != '/' && request.path_info != '/error' && request.path_info != '/showlogin' && request.path_info != '/laws' && request.path_info != '/log_out'
    redirect('/error')
  end
end