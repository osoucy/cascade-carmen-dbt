import os
import pandas as pd

# --------------------------------------------------------------------------- #
# Setup                                                                       #
# --------------------------------------------------------------------------- #

REGIONS = [
    "africa",
    "america",
    "asia",
    "atlantic",
    "australia",
    "europe",
    "indian",
    "pacific",
]

dirpath = "../data/"

# --------------------------------------------------------------------------- #
# Read Data                                                                   #
# --------------------------------------------------------------------------- #

for region in REGIONS:

    # Read
    df = pd.read_excel(os.path.join(dirpath, "carmen_sightings_20220629061307.xlsx"), sheet_name=region.upper())
    df["region"] = region

    # Write
    df.to_csv(os.path.join(dirpath, f"carmen_sightings_{region}.csv"), index=False)
