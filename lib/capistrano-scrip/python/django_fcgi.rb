require 'capistrano-scrip/utils'

Capistrano::Configuration.instance.load do
  namespace :django_fcgi do
    # Set django as :app_server
    _cset(:app_server) { "django_fcgi" }
    # Python executable path
    _cset(:python) { "python" }
    # Template name for django fcgi init script
    _cset(:django_fcgi_template) { "django_fcgi.sh.erb" }
    # Where django fcgi init script will be uploaded to
    _cset(:django_fcgi_script_path) { "/etc/init.d/#{application}.sh" }
    # Path to django socket
    _cset(:django_fcgi_socket_path) { "#{shared_path}/socket/django_fcgi.sock" }
    # Path to django fcgi pidfile
    _cset(:django_fcgi_pid_path) { "#{shared_path}/pids/django_fcgi.pid" }

    host_task :setup_host do
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

    django_fcgi.setup_host if Capistrano::CLI.ui.agree("Create fcgi-related files? [y/n]")
  end
  after 'deploy:setup' do
    django_fcgi.setup if Capistrano::CLI.ui.agree("Create fcgi run script? [y/n]")
  end
  after 'deploy:symlink', 'django_fcgi:restart'
end
