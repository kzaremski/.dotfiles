# Konstantin Zaremski
#   August 27, 2023
# 
# dotfiles.py
#   This python script manages the dotfiles repository, saving or loading all changes
# 
# Usage
#   ...
#
# License
#   MIT, to be inserted later
#

# Import dependencies
import sys

def main(args):
    # Parse arguments and determine desired mode
    mode = None
    if "--save" in args or "-s" in args:
        mode = "SAVE"
    elif "--load" in args or "-l" in args:
        mode = "LOAD"
    else:
        return print("No action provided, you must be explicit!")



if __name__ == "__main__":
    main(sys.argv) 

