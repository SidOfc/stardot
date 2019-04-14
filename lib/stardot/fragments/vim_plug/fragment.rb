# frozen_string_literal: true

class VimPlug < Stardot::Fragment
  PLUGGED   = File.expand_path('~/.vim/plugged').freeze
  PLUG_REPO = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  PLUG_DIR  = File.expand_path('~/.local/share/nvim/site/autoload').freeze
  PLUG_FILE = File.join(PLUG_DIR, 'plug.vim').freeze

  queued def plug(repo, **_opts)
    if plug? repo
      if up_to_date? repo
        info "#{repo} is up to date"
      else
        perform_pull repo
        info "updated #{repo}"
      end
    else
      perform_clone repo
      ok "installed #{repo}"
    end
  end

  def root(path = nil)
    @root = File.expand_path path if path
    @root ||= PLUGGED
  end

  private

  def up_to_date?(repo)
    run_silent "git -C #{root}/#{repo_dirname(repo)} fetch"

    local  = bash "git -C #{root}/#{repo_dirname(repo)} rev-parse HEAD"
    remote = bash "git -C #{root}/#{repo_dirname(repo)} rev-parse '@{u}'"

    local == remote
  end

  def perform_pull(repo)
    run_silent "git -C #{root}/#{repo_dirname(repo)} pull"
  end

  def perform_clone(repo)
    destination = "#{root}/#{repo_dirname(repo)}"
    run_silent "git clone https://github.com/#{repo} #{destination}"
  end

  def plug?(repo)
    Dir.exist? File.join(root, repo_dirname(repo))
  end

  def repo_dirname(repo)
    repo.split('/').pop
  end

  def install_plug
    load_while 'installing vim-plug' do
      run_silent "curl -fLo #{PLUG_FILE} --create-dirs #{PLUG_REPO} --silent"
    end
  end
end
