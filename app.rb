require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

require_relative './model.rb'


enable :sessions

unProtectedRoutes = ["/", "/register", "/showlogin", "/laws", "/log_out", "/laws", "/districts", "/laws/*/allowed", "/district/*/allowed"]
#ändra routenamns om det går, så de blir som de två sista på raden ovan. laws/:id och districts/:id behövs här 

before do
  if security(unProtectedRoutes)
    redirect('/error')
  end
end

get('/')  do
  prime_minister = hem()
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
  password = params[:password]
  password_confirm = params[:password_confirm]
  access = params[:access]

  result= register(username, access, password, password_confirm)
  
  if true
    redirect('/showlogin')

  else
    redirect('/register/error')
  end
end

get('/ministers') do 
  all_users = all_users()
  slim(:"ministers/index", locals:{all_users:all_users})
end

get('/ministers/:id') do 
  id = params[:id].to_i
  result = a_minister(id)
  district = a_ministers_district(id) 
  slim(:"ministers/show", locals:{result:result, district:district})
end

post('/ministers/:id/delete') do
  id = params[:id].to_i
  minister_delete(id)
  redirect('/ministers')
end

get('/ministers/:id/edit') do
  id = params[:id].to_i
  user_info = minister_edit(id)
  slim(:"/ministers/edit", locals:{user_info:user_info})
end

post('/ministers/:id/update') do 
  id = params[:id].to_i
  name = params[:name]
  access = params[:access]
  minister_update(name, access, id)
  redirect('/ministers') 
end

get('/laws') do
  result = all_laws()
  slim(:"laws/index", locals:{the_laws:result})
end

get('/all_laws') do
  result = all_laws()
  slim(:"laws/index_loged_in", locals:{the_laws:result})
end

get('/laws/error') do
  slim(:"/laws/errors")
end

get('/laws/new') do
  all_info = law_create()
  result = all_info[0]
  all_districtnames = all_info[1]
  slim(:"laws/new", locals:{result:result, all_districtnames:all_districtnames})
end

post('/laws/new') do
  law_name = params[:law_name]
  description = params[:description]
  time = Time.now.strftime('%a, %d %b %Y %H:%M:%S').to_s


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
      district_name = new_law_ministers(law_name, description, time)
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

get('/laws/:id') do 
  id = params[:id].to_i
  all = laws_id(id)
  result = all[0]
  all_districts = all[1]
  responseble = all[2]

  slim(:"laws/show", locals:{result:result, all_districts:all_districts, responseble:responseble})
end

post('/laws/:id/delete') do
  id = params[:id].to_i

  if laws_delete(id) == false
    redirect('/authorised')
  end
end

post('/laws/:id/update') do 
  id = params[:id].to_i
  name = params[:name]
  description = params[:description]
  
  if laws_update(id, name, description) == false
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

get('/districts') do
  district_info = district()
  slim(:"districts/index", locals:{the_districts:district_info})
end

get('/all_districts') do
  district_info = district()
  slim(:"districts/index_loged_in", locals:{the_districts:district_info})
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

  if district_new(district_name, access_number)
    redirect('/all_districts')
  else
    redirect('/districts/error')
  end
end

get('/districts/:id/edit') do
  id = params[:id].to_i
  result = district_edit(id)
  slim(:"/districts/edit", locals:{result:result})
end

post('/districts/:id/update') do 
  id = params[:id].to_i
  name = params[:name]
  access = params[:access]

  if district_update(id, name, access)
    redirect('/all_districts')
  else
    redirect('/authorised')
  end
end

post('/districts/:id/delete') do
  id = params[:id].to_i


  if district_delete(id)
    redirect('/all_districts')
  else 
    redirect('/authorised')
  end
end

get('/districts/:id') do 
  id = params[:id].to_i
  result = a_district(id)
  info_district = result[0]
  all_laws = result[1]
  slim(:"districts/show", locals:{result:info_district, laws_of_district:all_laws})
end 