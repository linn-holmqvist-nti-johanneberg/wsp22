require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative './model.rb'

enable :sessions

include Model

unProtectedRoutes = ["/", "/register", "/showlogin", "/laws", "/log_out", "/districts", "/laws/*/allowed", "/district/*/allowed"]


# Attempts to check if the client has authorization and updates the session and redirects to '/error'
# 
# @see Model#security
before do
  user_access_number = session[:user_access]
  if security(unProtectedRoutes, user_access_number)
    redirect('/error')
  end
end 

# Display Landing Page
get('/')  do
  prime_minister = hem()
  slim(:"hem", locals:{prime_minister:prime_minister})
end 

# Displays an error message
get('/empty_field') do
  slim(:something_empty)
end

# Displays an error message
get('/length') do
  slim(:length)
end

# Displays a login form
get('/showlogin') do
  session[:id] = []
  session[:user_access] = []
  slim(:login)
end

# Displays an error message
get('/authorised') do 
  slim(:authorised)
end

# Displays an error message
get('/error') do
  slim(:error)
end

# Displays an error message 
get('/login/error') do
  session[:id] = []
  session[:user_access] = []
  slim(:login_error)
end


# Attempts login and updates the session
#
# @param [String] :username, the username of the user
# @param [String] :password, the password of the user
#
# @see Model#login

post('/login') do
  username = params[:username]
  password = params[:password]

  result = login(username, password)
  

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

# Displays a log out site
get('/log_out') do
  session[:id] = []
  session[:user_access] = []
  slim(:"log_out")
end

# Displays a register form
get('/register') do
  slim(:register)
end

# Displays an error message
get('/register/error') do
  slim(:register_error)
end

# Displays an error message
get('/cool_down') do
  slim(:cool_down)
end


# Attempts register and redirects to '/showlogin'
#
# @param [string] :username, the username of the user
# @param [string] :password, the password of the user
# @param [string] :password_confirm, doubblechecked password
# @param [integer] :access, the accessnumber of the user
# 
# @see Model#is_it_empty
# @see Model#long
# @see Model#cool_down

post('/user/new') do
  username = params[:username]
  password = params[:password]
  password_confirm = params[:password_confirm]
  access = params[:access]

  if is_it_empty(username)
    redirect('/empty_field')
  end

  if is_it_empty(password)
    redirect('/empty_field')
  end
  
  if is_it_empty(password_confirm)
    redirect('/empty_field')
  end

  if is_it_empty(access)
    redirect('/empty_field')
  end

  if long(username)
    redirect('/length')
  end

  if session[:time] == nil 
    session[:time] = 0
  end

  
  result= register(username, access, password, password_confirm)
  
  if result
    redirect('/showlogin')

  else
    redirect('/register/error')
  end
end


# Displays all users
#
# @see Model#all_users
get('/ministers') do 
  all_users = all_users()
  slim(:"ministers/index", locals:{all_users:all_users})
end

# Displays a single user
# 
# @param [Integer] :id, the id of the user
#
# @see Model#a_minister
# @see Model#a_ministers_district
get('/ministers/:id') do 
  id = params[:id].to_i
  result = a_minister(id)
  district = a_ministers_district(id) 
  slim(:"ministers/show", locals:{result:result, district:district})
end

# Deletes an existing user and redirects to '/ministers'
#
# @param [Integer] :id, the id of the user
#
# @see Model#minister_delete

post('/ministers/:id/delete') do
  if session[:user_access] == 1
    id = params[:id].to_i
    minister_delete(id)
    redirect('/ministers')
  else
    redirect('/authorised')
  end
end


# Displays a single law updating form
#
# @param [Integer] :id, the id of the user
#
# @see Model#minister_edit
get('/ministers/:id/edit') do
  id = params[:id].to_i
  user_info = minister_edit(id)
  slim(:"/ministers/edit", locals:{user_info:user_info})
end


# Updates an existing article and redirects to '/ministers'
#
# @param [Integer] :id, the id of the user
# @param [String] :name, the name of the user
# @param [Integer] :access, the accessnumber of the user
#
# @see Model#it_is_empty
# @see Model#long
# @see Model#minister_update

post('/ministers/:id/update') do 
  if session[:user_access] == 1
    id = params[:id].to_i
    name = params[:name]
    access = params[:access]
    user_access_number = session[:user_access]

    if is_it_empty(access)
      redirect('/empty_field')
    end

    if is_it_empty(id)
      redirect('/empty_field')
    end

    if is_it_empty(name)
      redirect('/empty_field')
    end

    if long(name)
      redirect('/length')
    end

    minister_update(name, access, id)
    redirect('/ministers') 
  else
    redirect('/authorised')
  end
end

# Displays all Laws
#
# @see Model#all_laws
get('/laws') do
  result = all_laws()
  slim(:"laws/index", locals:{the_laws:result})
end


# Displays all Laws
#
# @see Model#all_laws
get('/all_laws') do
  result = all_laws()
  slim(:"laws/index_loged_in", locals:{the_laws:result})
end

# Displays an error message
get('/laws/error') do
  slim(:"/laws/errors")
end

# Displays a new Law form
#
# @see Model#law_create
get('/laws/new') do
  user_access_number = session[:user_access]
  all_info = law_create(user_access_number)
  result = all_info[0]
  all_districtnames = all_info[1]
  slim(:"laws/new", locals:{result:result, all_districtnames:all_districtnames})
end

# Creates a new law and redirects to '/all_laws'
#
# @param [String] :law_name, the name of the Law
# @param [String] :description, the description of the Law
#
# @see Model#is_it_empty
# @see Model#no_double
# @see Model#law_new_president
# @see Model#enter_new_lawdistrict
# @see Model#new_law_ministers
# @see Model#new_law_ministers_part2

post('/laws/new') do

  law_name = params[:law_name]
  description = params[:description]
  time = Time.now.strftime('%a, %d %b %Y %H:%M:%S').to_s
  user_access_number = session[:user_access]
  if is_it_empty(law_name)
    redirect('/empty_field')
  end

  if is_it_empty(description)
    redirect('/empty_field')
  end

  if no_double(law_name)
    if session[:user_access] == 1
      district_name = params[:district_name]
      district_name2 = params[:district_name2]
      district_name3 = params[:district_name3]
      access_number = params[:access_number]
      access_number2 = params[:access_number2]
      access_number3 = params[:access_number3]
      
      law_new_president(law_name, description, time)

      enter_new_lawdistrict(law_name, district_name, access_number, time)
      enter_new_lawdistrict(law_name, district_name2, access_number2, time)
      enter_new_lawdistrict(law_name, district_name3, access_number3, time)

      redirect('/all_laws')
  
    elsif session[:user_access] != []
      district_name = new_law_ministers(law_name, description, time, user_access_number)
      district_name = district_name["district_name"]
      new_law_ministers_part2(law_name, time, district_name)

      redirect('/all_laws')

    else 
      redirect('/error')
    end
  else
    redirect('/laws/error')
  end

end

# Display a Law updating form
#
# @param [Integer] :id, the id of the Law
#
# @see Model#laws_edit
get('/laws/:id/edit') do  
  id = params[:id].to_i
  all = laws_edit(id)
  all_info_law = all[0]

  if all[1] == nil
    all_info_district1 = ""
  else
    all_info_district1 = all[1]
  end

  if all[2] == nil
    all_info_district2 = ""
  else
    all_info_district2 = all[2]
  end

  if all[3] == nil
    all_info_district3 = ""
  else
    all_info_district3 = all[3]
  end
  
  slim(:"/laws/edit", locals:{all_info_law:all_info_law, all_info_district1:all_info_district1, all_info_district2:all_info_district2, all_info_district3:all_info_district3})
end


# Display a single Law 
#
# @param [Integer] :id, the id of the Law
#
# @see Model#laws_id
get('/laws/:id/allowed') do 
  id = params[:id].to_i
  all = laws_id(id)
  result = all[0]
  all_districts = all[1]
  responseble = all[2]

  slim(:"laws/show", locals:{result:result, all_districts:all_districts, responseble:responseble})
end

# Deletes an existing law and redirects to '/all_laws'
#
# @param [Integer] :id, the id of the Law
#
# @see Model#laws_delete
post('/laws/:id/delete') do
  id = params[:id].to_i
  user_access_number = session[:user_access]
  if laws_delete(id, user_access_number) 
    redirect('/all_laws')
  else
    redirect('/authorised')
  end
end

# Updates an existing law and redirects to '/all_laws'
#
# @param [Integer] :id, the id of the Law
# @param [String] :name, the name of the Law
# @param [String] :desription, the desription of the Law
#
# @see Model#is_it_empty
# @see Model#laws_update
# @see Model#law_update_president
post('/laws/:id/update') do 
  user_access_number = session[:user_access]
  id = params[:id].to_i
  name = params[:name]
  description = params[:description]
  
  if is_it_empty(name)
    redirect('/empty_field')
  end  

  if is_it_empty(description)
    redirect('/empty_field')
  end

  if laws_update(id, name, description, user_access_number) == false
    redirect('/authorised')
  end

  result = laws_update(id, name, description)
  district_access1 = result[0]
  district_access2 = result[1]
  district_access3 = result[2]

  if session[:user_access] == 1 

    district_name1 = params[:district1]
    district_name2 = params[:district2]
    district_name3 = params[:district3]      


    if district_name1 != nil 
      law_update_president(district_name1, district_access1)
    end

    if district_name2 != nil 
      law_update_president(district_name2, district_access2)
    end

    if district_name3 != nil 
      law_update_president(district_name3, district_access3)
    end

  end

  redirect('/all_laws') 
end

# Displays all Districts
#
# @see Model#district
get('/districts') do
  district_info = district()
  slim(:"districts/index", locals:{the_districts:district_info})
end

# Displays all Districts
#
# @see Model#district
get('/all_districts') do
  district_info = district()
  slim(:"districts/index_loged_in", locals:{the_districts:district_info})
end

# Displays a new District form
get('/districts/new') do
  slim(:"districts/new")
end

# Displays an error message
get('/districts/error') do
  slim(:"districts/error")
end

# Creates a new District and redirects to '/all_districts'
#
# @param [String] :district_name, the name of the district
# @param [Integer] :access_number, the access number of the district
#
# @see Model#is_it_empty
# @see Model#district_new
post('/districts/new') do
  district_name = params[:district_name]
  access_number = params[:access_number]

  if is_it_empty(district_name)
    redirect('/empty_field')
  end

  if is_it_empty(access_number)
    redirect('/empty_field')
  end

  if district_new(district_name, access_number)
    redirect('/all_districts')
  else
    redirect('/districts/error')
  end
end

# Display a District updating form
#
# @param [Integer] :id, the id of the district
#
# @see Model#district_edit
get('/districts/:id/edit') do
  id = params[:id].to_i
  result = district_edit(id)
  slim(:"/districts/edit", locals:{result:result})
end

# Updates an existing District and redirects to '/all_districts'
#
# @param [Integer] :id, the id of the District
# @param [String] :name, the name of the District
# @param [Integer] :access, the access number of the District
#
# @see Model#is_it_empty
# @see Model#district_update
post('/districts/:id/update') do 
  id = params[:id].to_i
  name = params[:name]
  access = params[:access]

  user_access_number = session[:user_access]

  if is_it_empty(access)
    redirect('/empty_field')
  end

  if is_it_empty(name)
    redirect('/empty_field')
  end

  if district_update(id, name, access, user_access_number)
    redirect('/all_districts')
  else
    redirect('/authorised')
  end
end

# Deletes an existing District and redirects to '/all_district'
#
# @param [Integer] :id, the id of the District
#
# @see Model#district_delete
post('/districts/:id/delete') do
  id = params[:id].to_i
  user_access_number = session[:user_access]

  if district_delete(id, user_access_number)
    redirect('/all_districts')
  else 
    redirect('/authorised')
  end
end

# Display a single District 
#
# @param [Integer] :id, the id of the District
#
# @see Model#a_district
get('/districts/:id/allowed') do 
  id = params[:id].to_i
  result = a_district(id)
  info_district = result[0]
  all_laws = result[1]
  slim(:"districts/show", locals:{result:info_district, laws_of_district:all_laws})
end 