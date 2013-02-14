Capistrano::Configuration.instance.load do
  namespace :django_fcgi do
    _cset(:app_server) { "django_fcgi" }
    _cset(:python) { "python" }
    _cset(:django_fcgi_template) { "django_fcgi.sh.erb" }
    _cset(:django_fcgi_script_path) { "/etc/init.d/#{application}.sh" }
    _cset(:django_fcgi_socket_path) { "#{shared_path}/socket/django_fcgi.sock" }
    _cset(:django_fcgi_pid_path) { "#{shared_path}/pids/django_fcgi.pid" }

    task :setup_host do
      script_name = File.basename django_fcgi_script_path
      # Create fcgi script, allow user to modify it
      run "#{sudo} touch #{django_fcgi_script_path}"
      run "#{sudo} chown #{deploy_user}:#{group} #{django_fcgi_script_path}"
      run "#{sudo} chmod u+x #{django_fcgi_script_path}"
      # Run fcgi script on system startup
      run "#{sudo} update-rc.d -f #{script_name} start 99 2 3 4 5 ."
      run "#{sudo} update-rc.d -f #{script_name} stop 99 0 6 ."
    end

    task :start do
      run "#{django_fcgi_script_path} start"
    end
    task :restart do
      run "#{django_fcgi_script_path} restart"
    end
    task :stop do
      run "#{django_fcgi_script_path} stop"
    end
    task :setup do
      generate_config(django_fcgi_template, django_fcgi_script_path)
    end

    desc "Parses config file and outputs it to STDOUT (internal task)"
    task :parse_script, :roles => :app , :except => { :no_release => true } do
      puts parse_template(django_fcgi_template)
    end
  end

  after 'host:setup' do
    create_remote_dir(File.dirname(django_fcgi_socket_path)) if django_fcgi_socket_path

    django_fcgi.setup_host if Capistrano::CLI.ui.agree("Create fcgi-related files? [Yn]")
  end
  after 'deploy:setup' do
    django_fcgi.setup if Capistrano::CLI.ui.agree("Create fcgi run script? [Yn]")
  end
  after 'deploy:symlink', 'django_fcgi:restart'
end