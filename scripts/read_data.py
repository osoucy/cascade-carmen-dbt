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

# --------------------------------------------------------------------------- #
# Read Data                                                                   #
# --------------------------------------------------------------------------- #

for region in REGIONS:

    # Read
    df = pd.read_excel("../data/carmen_sightings_20220629061307.xlsx", sheet_name=region.upper())
    df["region"] = region

    # Write
    df.to_csv(f"../seeds/brz_carmen_sightings_{region}.csv", index=False)
