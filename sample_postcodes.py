import os
import zipfile
import requests
import pandas as pd

# Download the ZIP file if the CSV file doesn't exist
if not os.path.exists("postcodes.csv"):
    url = "https://www.doogal.co.uk/files/postcodes.zip"
    r = requests.get(url)
    with open("postcodes.zip", "wb") as f:
        f.write(r.content)

    # Extract the CSV file from the ZIP
    with zipfile.ZipFile("postcodes.zip", "r") as zip_ref:
        zip_ref.extractall()

    # Remove the ZIP file
    os.remove("postcodes.zip")

# Read the CSV file into a DataFrame
postcodes = pd.read_csv("postcodes.csv")

# Filter the DataFrame to include only rows where 'In.Use.' is 'Yes'
# and select the 'Postcode', 'Constituency', and 'Region' columns
postcodes = postcodes.loc[postcodes['In.Use.'] == 'Yes', ['Postcode', 'Constituency', 'Region']]

# Create a random subset of 500 postcodes
postcode_sample = postcodes.sample(n=500, random_state=1019)

# Write the random subset to a new CSV file
postcode_sample.to_csv("postcodes_sample.csv", index=False)
