# frozen_string_literal: true

class VimPlug < Stardot::Fragment
  PLUGGED   = File.expand_path('~/.vim/plugged').freeze
  PLUG_REPO = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  PLUG_DIR  = File.expand_path('~/.local/share/nvim/site/autoload').freeze
  PLUG_FILE = File.join(PLUG_DIR, 'plug.vim').freeze

  queued def plug(repo, **opts)
    if plug? repo
      if up_to_date? repo
        info "#{repo} is up to date"
      else
        perform_pull(repo, **opts)
        warn "updated #{repo}"
      end
    else
      perform_clone(repo, **opts)
      ok "installed #{repo}"
    end
  end

  def root(path = nil)
    @root = File.expand_path path if path
    @root ||= PLUGGED
  end

  def path_to(plug_name)
    File.join root, plug_name
  end

  private

  def up_to_date?(repo)
    run_silent "git -C #{root}/#{repo_dirname(repo)} fetch"

    local  = bash "git -C #{root}/#{repo_dirname(repo)} rev-parse HEAD"
    remote = bash "git -C #{root}/#{repo_dirname(repo)} rev-parse '@{u}'"

    local == remote
  end

  def perform_pull(repo, **opts)
    branch = opts.fetch :branch, ''
    run_silent "git -C #{root}/#{repo_dirname(repo)} pull #{branch}"
  end

  def perform_clone(repo, **opts)
    dest        = "#{root}/#{repo_dirname(repo)}"
    branch_opts = "-b #{opts[:branch]} --single-branch" if opts[:branch]

    run_silent "git clone #{branch_opts} #{repo_path(repo)} #{dest}"
  end

  def repo_path(repo)
    return File.expand_path(repo) if %w[~ . /].any? { |x| repo.start_with? x }

    "https://github.com/#{repo}"
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
