import os
import pandas as pd
from sqlalchemy import create_engine
from sqlalchemy import inspect

# --------------------------------------------------------------------------- #
# Engine                                                                      #
# --------------------------------------------------------------------------- #

DATABASE = 'osoucy'
USER = 'osoucy'
PASSWORD = 'none'
HOST = 'localhost'
PORT = '5432'

engine = create_engine(f"postgresql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}")
inspector = inspect(engine)


# --------------------------------------------------------------------------- #
# Read Data                                                                   #
# --------------------------------------------------------------------------- #

df = pd.read_sql_table("slv_carmen_sightings", con=engine, schema="default")
print(df.columns)

# --------------------------------------------------------------------------- #
# Identify Dimensions                                                         #
# --------------------------------------------------------------------------- #

dims = [
    ["city", "country", "latitude", "longitude", "region"],
]

for dim in dims:
    _df = df[dim]
    n = len(_df.drop_duplicates())
    assert df[dim[0]].nunique() == n


