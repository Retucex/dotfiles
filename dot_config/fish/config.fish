source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

#######################
###### FUNCTIONS ######
####################### 

# Wrap cd to run ls after successful directory change
function cd
    builtin cd $argv; and ls
end

# Run last command with sudo
function fuck
    set -l raw (history | head -n 1)
    # strip leading timestamp: YYYY-MM-DD HH:MM:SS
    set -l cmd (printf "%s" "$raw" | sed -E 's/^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} //')
    if test -z "$cmd"
        echo "No previous command found."
        return 1
    end
    eval "sudo $cmd"
end

#######################
#### ABBREVIATIONS ####
####################### 

abbr --add paci sudo pacman -S      # Install package
abbr --add pacr sudo pacman -Rs     # Uninstall package 
abbr --add pacu sudo pacman -Syu    # Update all packages
abbr --add pacl pacman -Qe          # List explicitely installed packages
abbr --add pacs pacman -Ss          # Search database

abbr --add fcc fish_clipboard_copy

abbr --add aider aider --model ollama_chat/batiai/qwen3.6-35b:iq4 --edit-format whole

abbr --add ai interpreter --model ollama/batiai/qwen3.6-35b:iq4 --api_base http://127.0.0.1:11434 --safe_mode ask --no-llm_supports_functions -y



#######################
###### VARIABLES ######
#######################

set -gx EDITOR code


# Point Aider to your local ROCm Ollama instance
set -gx OLLAMA_API_BASE "http://127.0.0.1:11434"
