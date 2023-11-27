 # Parse CVAA

This is an experimental repository for a query about
parsing data from cvaa files.



## Description

The script takes a dataset (`data/Accesses 1.cvaa`) and performs the following operations:

1. Extracts the information for each point, including: lat, long, alt, number of accesses, and start/end time for each access.
2. Calculates the revisit time for each pair of subsequent point. 
3. Aggregates and plots the mean revisit time for each group on a world map, with the color of each point representing the mean revisit time.

## Usage

The `parse_cvaa.R` script in this folder is used to calculate and visualize the pass time for 
different points on a world map. Documentation on how this is done is contained within the script.

To use this script, you need to have R installed on your machine.
Please make sure you are in folder's directory. Copy
any data you plan to use into your working directory. Then modify
`parse_cvaa.R` to load data from this file. In the original
file, the line to modify looks as follows:

```
#--------------------------------------------
# Specifying File Path
#--------------------------------------------
# This is the path to the file. Please replace this with the path to your file.
file_path <- "./data/Accesses 1.cvaa"
```

### Dependencies

I have used `renv` to manage dependencies. Before running the 
script, please make sure `renv` is installed with the command:

```
install.packages('renv')
```

Once installed, you can install dependencies using the command:

```
renv::restore()
```
