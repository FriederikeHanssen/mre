#!/usr/bin/env python3

import pandas as pd

# for i in "${npz}": 

# Load the JSON and NPZ files
df = pd.read_json("${json}")

# Round all values to 2 decimal digits
df = df.round(2)

df.to_csv(f"output.tsv", sep="\t", index=False)