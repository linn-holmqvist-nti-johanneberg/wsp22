require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

get('/')  do
  slim(:hem)
end 

get('/showlogin') do
  slim(:login)
end

post('/login') do
  username = params[:username]
  password = params[:password]
  db = SQLite3::Database.new('db/laws.db')
  db.results_as_hash = true
  result = db.execute("SELECT * FROM user WHERE username = ?", username).first
  password_digest= result["password_digest"]
  id = result["id"]

  if BCrypt::Password.new(password_digest) == password
    redirect('/todos')
  else
    "FEL LÖSENORD, VAR VÄNLIG FÖRSÖK IGEN"
  end

end

get ('/todos') do
  slim(:todos/index)
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








#VIDEO 3 ungefär vid 11 min. Du har ett problem du måste lösa