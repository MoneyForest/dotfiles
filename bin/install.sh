# set directory
current_dir=`pwd`

# set dotfiles
dotfiles[0]=gitconfig
dotfiles[1]=gitconfig_global
dotfiles[2]=vimrc

for dotfile in ${dotfiles[@]}
do
  ln -snf $current_dir/$dotfile ~/.$dotfile  
done
