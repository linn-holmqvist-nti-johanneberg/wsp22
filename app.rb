require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

get('/')  do
  slim(:register)
end 
  
post('/users/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]

  if (password==password_confirm)
    password_digest = BCrypt::Password.create(password)
    db = SQLite3::Database.new('db/laws.db')
    db.execute("INSERT INTO")

  else 
    "Lösenorden matchar inte! Testa igen"

end