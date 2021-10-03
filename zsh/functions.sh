function gmd(){
    echo "Enter the source repo url: "
    read source_repo_url
    echo "Enter the source repo name: "
    read source_repo_name
    echo "Enter the source branch: "
    read source_branch
    echo "Enter the source folder: "
    read source_folder
    echo "Enter the target repo url: "
    read target_repo_url
    echo "Enter the target repo name: "
    read target_repo_name

    git clone $source_repo_url
    git clone $target_repo_url
    cd $source_repo_name
    git filter-branch --subdirectory-filter $source_folder -- -- all
    git reset --hard
    git gc --aggressive
    git prune
    git clean -fd
    mkdir $source_folder
    git mv -k * ./$source_folder
    git commit -m "chore: collected the folders we need to move"
    cd ../$target_repo_name
    git remote add $source_repo_name ../$source_repo_name/
    git fetch $source_repo_name
    git branch $source_repo_name remotes/$source_repo_name/master
    git merge $source_repo_name --allow-unrelated-histories
    git remote rm $source_repo_name
    git branch -d $source_repo_name
    git commit -m "chore: move files from $source_repo_name into $target_repo_name"
}

function load() {
	if [ -z $1 ]; then
		echo "Must supply an argument"
	else
		if [[ $1 == *\/* ]]; then
			name=$(echo $1 | cut -d '/' -f2)
			if [[ ! -e $ZSH_PLUGGIN/$1 ]]; then
				git ls-remote -q -h https://github.com/$1 > /dev/null
				if [ $? -eq 0 ]; then
					git clone -q https://github.com/$1 $ZSH_PLUGGIN$name 2>/dev/null
					source $ZSH_PLUGGIN$name/$name.zsh
				else
					echo "Pluggin not found. Check the name."
				fi
			else
				source $ZSH_PLUGGIN$name/$name.zsh
			fi
		else
			echo "'$1' must have the following form user/repo"
		fi
	fi
}
