require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/')  do
  slim(:hem)
end 

get('/laws') do

  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM laws")
  slim(:"laws/index", locals:{the_laws:result})
end

get('/laws/new') do
  slim(:"laws/new")
end

post('/laws/new') do
  law_name = params[:law_name]
  description = params[:description]
  district = params[:district]
  access_number = params[:access_number].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.execute("INSERT INTO laws (law_name, description) VALUES (?,?)", law_name, description)
  db.execute("INSERT INTO district (district_name, access) VALUES (?,?)", district, access_number)
  redirect('/laws')
end

get('/laws/:id') do 
  id = params[:id].to_i
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM laws WHERE law_id = ?", id).first
  result2 = db.execute("SELECT district_name FROM district WHERE district_id IN (SELECT district_id FROM law_district_relation WHERE law_id = ?)", id).first
  slim(:"laws/show", locals:{result:result,result2:result2})
end





























get('/showlogin') do
  slim(:login)
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT username, password FROM user WHERE username = ?", username).first
  password_digest= result["password"]
  id = result["id"]

  if BCrypt::Password.new(password_digest) == password
    session[:id] = id
    redirect('/laws')
  else
    "FEL LÖSENORD, VAR VÄNLIG FÖRSÖK IGEN"
  end

end

get ('/register') do
  slim(:register)
end

post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  access = params[:access]

  if (password==password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/laws.db')
    db.execute("INSERT INTO user (username, password, access) VALUES (?, ?, ?)", username, password_digest, 1)
    redirect('/')
    

  else 
    "Lösenorden matchar inte! Testa igen"
  end

end