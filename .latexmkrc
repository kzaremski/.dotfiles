# Konstantin Zaremski's latexmk Configuration
# Last updated: October 11, 2025

# Use pdflatex by default
$pdf_mode = 1;

# Use Skim as PDF previewer on macOS
$pdf_previewer = 'open -a Skim';

# Don't automatically open a new viewer window with -pvc
$new_viewer_always = 0;

# Automatically open PDF viewer when compiling
$preview_mode = 0;
$preview_continuous_mode = 0;

# Update viewer when PDF changes (for -pvc mode)
$pdf_update_method = 4;  # Update viewer but don't open if not already open

# Clean up auxiliary files
$clean_ext = 'synctex.gz synctex.gz(busy) run.xml tex.bak bbl bcf fdb_latexmk run tdo %R-blx.bib';
