symlink do
  ln '.dotfiles/bin/',          'bin/'
  ln '.dotfiles/init.vim',      '.config/nvim/'
  ln '.dotfiles/config.fish',   '.config/fish/'
  ln '.dotfiles/alacritty.yml', '.config/alacritty/'
  ln '.dotfiles/.asdfrc'
  ln '.dotfiles/.default-gems'
  ln '.dotfiles/.gitconfig'
  ln '.dotfiles/.gitignore'
  ln '.dotfiles/.rgignore'
  ln '.dotfiles/.tmux.conf'
end

brew do
  install :alacritty, options: ['--HEAD']
  install :fish
  install :tmux
  install :neovim
  install :autojump
  install :grip
  install :wget
  install :fzf
  install :rg
  install :gnupg
  install 'pinentry-mac'
  install :graphicsmagick
  install :imagemagick
  install 'youtube-dl'
  install :gifcicle
end

asdf do
  install :ruby,    versions: [:latest, '2.5.0', '2.4.0']
  install :nodejs,  versions: [:latest, '10.0.0', '9.11.0']
  install :crystal, versions: [:latest, '0.24.0']
  install :python,  versions: [:latest]
  install :rust,    versions: [:latest]
end

commands do
  run 'defaults write com.apple.finder AppleShowAllFiles YES'
  run 'defaults write com.apple.dock autohide-delay -float 1000; killall Dock'
end
